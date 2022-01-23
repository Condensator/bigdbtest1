SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[CalculateDaysPastDueWithRentShift]
(
	@JobStepInstanceId		BIGINT
	,@CustomerId			BIGINT
	,@UpdateThroughDate		DATETIME
	,@EntityTypeCT			NVARCHAR(2)
	,@ReceivableCategoryPayoff	NVARCHAR(16)
	,@ReceivableCategoryAssetSale NVARCHAR(16) 
	,@ReceivableCategoryPaydown NVARCHAR(16)	
	,@UserId				BIGINT
	,@ServerTimeStamp		DATETIMEOFFSET
	,@AccessibleLegalEntities CalculateDPDWithShiftLegalEntityId READONLY
)
AS
BEGIN

	-- Reset and Update ContractCollectionDetails.InterestDPD, RentOrPrincipalDPD, MaturityDPD, OverallDPD columns
	SET NOCOUNT ON;

	SELECT * INTO #OpenDueDayPastInvoices 
		FROM 
		(
			SELECT ReceivableInvoiceDetails.EntityID AS ContractId
				,ReceivableInvoices.Id AS InvoiceId
				,ReceivableInvoices.DueDate AS InvoiceDueDate
				,DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate), @UpdateThroughDate) AS AgeInDays
			FROM CollectionsJobExtracts
				INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.EntityId = CollectionsJobExtracts.ContractId
					AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT 
					AND ReceivableInvoiceDetails.IsActive = 1
				INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
					AND CollectionsJobExtracts.CustomerId = ReceivableInvoices.CustomerId -- ?? should join with customerid also? assumptions
					AND ReceivableInvoices.IsActive = 1 
				INNER JOIN LegalEntities ON LegalEntities.Id = ReceivableInvoices.LegalEntityId
				INNER JOIN Receivablecategories ON ReceivableInvoices.ReceivablecategoryId = Receivablecategories.id -- this was not there, added now
			WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
				AND (ReceivableInvoices.IsDummy = 0 OR (ReceivableInvoices.IsDummy = 1 AND Receivablecategories.Name NOT IN (@ReceivableCategoryPayoff, @ReceivableCategoryAssetSale, @ReceivableCategoryPaydown))) -- this was not there, added now
				AND ReceivableInvoices.DueDate <= @UpdateThroughDate
				AND (ReceivableInvoiceDetails.Balance_Amount > 0 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0)
			GROUP BY ReceivableInvoiceDetails.EntityID, ReceivableInvoices.Id, ReceivableInvoices.CustomerId, ReceivableInvoices.DueDate, LegalEntities.ThresholdDays 
		) 
		AllOpenInvoices 
		WHERE AllOpenInvoices.AgeInDays > 0

	CREATE INDEX IX_OpenDueDayPastInvoices_InvoiceId_ContractId ON #OpenDueDayPastInvoices(InvoiceId, ContractId);

	CREATE TABLE #DPDResult 
	(
		ContractId		BIGINT PRIMARY KEY, 
		InterestDPD		BIGINT, 
		PrincipalDPD	BIGINT, 
		OverallDPD		BIGINT, 
		MaturityDPD		BIGINT
	)


	INSERT INTO #DPDResult
		SELECT #OpenDueDayPastInvoices.ContractId, 
				0,
				0,
				0,
				0 
			FROM #OpenDueDayPastInvoices
			GROUP BY #OpenDueDayPastInvoices.ContractId


	--Interest DPD
	UPDATE #DPDResult 
			SET #DPDResult.InterestDPD = alias.InterestDPD
		FROM 
		(
			SELECT #OpenDueDayPastInvoices.ContractId AS ContractId
				,MAX(#OpenDueDayPastInvoices.AgeInDays) InterestDPD
			FROM #OpenDueDayPastInvoices
			WHERE EXISTS
				(
					SELECT * FROM ReceivableInvoiceDetails
						INNER JOIN ReceivableTypes ON ReceivableInvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
					WHERE ReceivableInvoiceDetails.ReceivableInvoiceId = #OpenDueDayPastInvoices.InvoiceId
						AND ReceivableInvoiceDetails.EntityId = #OpenDueDayPastInvoices.ContractId
						AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT 
						AND ReceivableInvoiceDetails.IsActive = 1
						AND receivabletypes.Name IN ('LoanInterest', 'LeaseFloatRateAdj', 'LeaseInterimInterest')
						AND ReceivableInvoiceDetails.IsActive = 1
				)
			GROUP BY #OpenDueDayPastInvoices.ContractId 
		) 
		alias 
		WHERE alias.ContractId = #DPDResult.ContractId


	--Maturity DPD with Rent shift
	SELECT * INTO #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForMaturityReceivables 
		FROM 
		(
			SELECT Invoices.Id AS InvoiceId,
				InvoiceDetails.EntityId AS ContractId,
				Invoices.DueDate,
				DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, Invoices.DueDate), @UpdateThroughDate) AS AgeInDays,
				SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) OriginalAmount
				,SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) - SUM(ISNULL(InvoiceDetails.Balance_Amount, 0)) AS AppliedAmount
			FROM ReceivableInvoices Invoices
				INNER JOIN LegalEntities ON LegalEntities.Id = Invoices.LegalEntityId
				INNER JOIN ReceivableInvoiceDetails InvoiceDetails ON Invoices.Id = InvoiceDetails.ReceivableInvoiceId 
					AND InvoiceDetails.EntityType = @EntityTypeCT
					AND InvoiceDetails.IsActive = 1
				INNER JOIN
				(
					SELECT ContractId, 
						MIN(InvoiceDueDate) AS InvoiceDueDate
					From #OpenDueDayPastInvoices 
					GROUP BY ContractId
				) 
				ContractWithMinimumDueDateOpenInvoices 
					ON ContractWithMinimumDueDateOpenInvoices.ContractId = InvoiceDetails.EntityId
				INNER JOIN ReceivableTypes ON InvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
			WHERE Invoices.IsActive = 1
				AND ReceivableTypes.Name IN ('OverTermRental', 'Supplemental')
				AND (@CustomerId = 0 OR Invoices.CustomerId = @CustomerId)
				AND Invoices.DueDate >= ContractWithMinimumDueDateOpenInvoices.InvoiceDueDate
			GROUP BY InvoiceDetails.EntityId, Invoices.Id, Invoices.DueDate, LegalEntities.ThresholdDays 
		)
		alias 
		WHERE alias.AgeInDays > 0


	SELECT ContractId
		,SUM(AppliedAmount) AS TotalAppliedAmount
	INTO #TotalAppliedAmountForMaturityReceivables
	FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForMaturityReceivables
	GROUP BY ContractId;


	WITH InvoiceBalanceAppliedAmount AS 
	(
		SELECT ContractId
			,InvoiceId
			,OriginalAmount
			,AgeInDays
			,DueDate
			,SUM(OriginalAmount) OVER (PARTITION BY contractid ORDER BY ContractId, DueDate) AS RunningContractCount
		FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForMaturityReceivables
	)


	UPDATE #DPDResult 
			SET MaturityDPD = AgeInDays
		FROM 
		(
			SELECT contractid
				,invoiceid
				,AgeInDays
				,ROW_NUMBER() OVER (PARTITION BY contractid ORDER BY contractid, DueDate) AS [Rank]
			FROM 
			(
				SELECT InvoiceBalanceAppliedAmount.contractid AS contractid
					,InvoiceBalanceAppliedAmount.invoiceid AS invoiceid
					,InvoiceBalanceAppliedAmount.AgeInDays
					,InvoiceBalanceAppliedAmount.DueDate
					,#TotalAppliedAmountForMaturityReceivables.TotalAppliedAmount - InvoiceBalanceAppliedAmount.RunningContractCount AS [difference]
				FROM InvoiceBalanceAppliedAmount
					INNER JOIN #TotalAppliedAmountForMaturityReceivables ON InvoiceBalanceAppliedAmount.ContractId = #TotalAppliedAmountForMaturityReceivables.ContractId
			) 
			aliasTable1
			WHERE [difference] < 0
		) 
		AllInvoiceAmountGreaterThanContractAppliedAmount
		WHERE AllInvoiceAmountGreaterThanContractAppliedAmount.[Rank] = 1 
			AND #DPDResult.ContractId = AllInvoiceAmountGreaterThanContractAppliedAmount.ContractId

	-- Principal DPD with Rent shift
	SELECT * INTO #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForPrincipalReceivables 
		FROM 
		(
			SELECT Invoices.Id AS InvoiceId,
				InvoiceDetails.EntityId AS ContractId,
				Invoices.DueDate,
				DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, Invoices.DueDate), @UpdateThroughDate) AS AgeInDays,
				SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) OriginalAmount
				,SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) - SUM(ISNULL(InvoiceDetails.Balance_Amount, 0)) AS AppliedAmount
			FROM ReceivableInvoices Invoices
				INNER JOIN LegalEntities ON LegalEntities.Id = Invoices.LegalEntityId
				INNER JOIN ReceivableInvoiceDetails InvoiceDetails ON Invoices.Id = InvoiceDetails.ReceivableInvoiceId 
					AND InvoiceDetails.EntityType = @EntityTypeCT
					AND InvoiceDetails.IsActive=1
				INNER JOIN
					(
						SELECT ContractId, 
							MIN(InvoiceDueDate) AS InvoiceDueDate
						FROM #OpenDueDayPastInvoices 
						GROUP BY ContractId
					) 
					ContractWithMinimumDueDateOpenInvoices 
						ON ContractWithMinimumDueDateOpenInvoices.ContractId = InvoiceDetails.EntityId
				INNER JOIN ReceivableTypes ON InvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
			WHERE Invoices.IsActive = 1
				AND ReceivableTypes.Name IN ('CPIBaseRental', 'CPIOverage', 'CapitalLeaseRental', 'InterimRental', 'LeaseFloatRateAdj', 'LeveragedLeaseRental', 'LoanPrincipal', 'OperatingLeaseRental')
				AND (@CustomerId = 0 OR Invoices.CustomerId = @CustomerId)
				AND Invoices.DueDate >= ContractWithMinimumDueDateOpenInvoices.InvoiceDueDate
			GROUP BY InvoiceDetails.EntityId, Invoices.Id, Invoices.DueDate, LegalEntities.ThresholdDays 
		)
		alias WHERE alias.AgeInDays > 0


	SELECT ContractId
			,SUM(AppliedAmount) AS TotalAppliedAmount
		INTO #TotalAppliedAmountForPrincipalReceivables
		FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForPrincipalReceivables
		GROUP BY ContractId;


	WITH InvoiceBalanceAppliedAmount AS 
	(
		SELECT ContractId
			,InvoiceId
			,OriginalAmount
			,AgeInDays
			,DueDate
			,SUM(OriginalAmount) OVER (PARTITION BY contractid ORDER BY ContractId, DueDate) AS RunningContractCount
		FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoicesForPrincipalReceivables
	)


	UPDATE #DPDResult 
			SET PrincipalDPD = AgeInDays
		FROM 
		(
			SELECT contractid
				,invoiceid
				,AgeInDays
				,ROW_NUMBER() OVER (PARTITION BY contractid ORDER BY contractid, DueDate) AS [Rank]
			FROM 
				(
				SELECT InvoiceBalanceAppliedAmount.contractid AS contractid
					,InvoiceBalanceAppliedAmount.invoiceid AS invoiceid
					,InvoiceBalanceAppliedAmount.AgeInDays
					,InvoiceBalanceAppliedAmount.DueDate
					,#TotalAppliedAmountForPrincipalReceivables.TotalAppliedAmount - InvoiceBalanceAppliedAmount.RunningContractCount AS [difference]
				FROM InvoiceBalanceAppliedAmount
					INNER JOIN #TotalAppliedAmountForPrincipalReceivables ON InvoiceBalanceAppliedAmount.ContractId = #TotalAppliedAmountForPrincipalReceivables.ContractId
			) 
			aliasTable1
			WHERE [difference] < 0
		) 
		AllInvoiceAmountGreaterThanContractAppliedAmount
		WHERE AllInvoiceAmountGreaterThanContractAppliedAmount.[Rank] = 1 
			AND #DPDResult.ContractId = AllInvoiceAmountGreaterThanContractAppliedAmount.ContractId

	--For Overall DPD
	SELECT * INTO #AllInvoicesAfterMinimumDueDateOfOpenInvoices 
		FROM 
		(
			SELECT Invoices.Id AS InvoiceId,
				InvoiceDetails.EntityId AS ContractId,
				Invoices.DueDate,
				DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, Invoices.DueDate), @UpdateThroughDate) AS AgeInDays,
				SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) OriginalAmount
				,SUM(ISNULL(InvoiceDetails.InvoiceAmount_Amount, 0)) - SUM(ISNULL(InvoiceDetails.Balance_Amount, 0)) AS AppliedAmount
			FROM ReceivableInvoices Invoices
				INNER JOIN LegalEntities ON LegalEntities.Id = Invoices.LegalEntityId
				INNER JOIN ReceivableInvoiceDetails InvoiceDetails ON Invoices.Id = InvoiceDetails.ReceivableInvoiceId 
					AND InvoiceDetails.EntityType = @EntityTypeCT
					AND InvoiceDetails.IsActive=1
				INNER JOIN
					(
						SELECT ContractId, 
							MIN(InvoiceDueDate) AS InvoiceDueDate
						From #OpenDueDayPastInvoices GROUP BY ContractId
					) 
					ContractWithMinimumDueDateOpenInvoices 
						ON ContractWithMinimumDueDateOpenInvoices.ContractId = InvoiceDetails.EntityId
				INNER JOIN ReceivableTypes ON InvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
			WHERE Invoices.IsActive = 1
				AND (@CustomerId = 0 OR Invoices.CustomerId = @CustomerId)
				AND Invoices.DueDate >= ContractWithMinimumDueDateOpenInvoices.InvoiceDueDate
			GROUP BY InvoiceDetails.EntityId, Invoices.Id, Invoices.DueDate, LegalEntities.ThresholdDays
		) 
		alias 
		WHERE alias.AgeInDays > 0


	SELECT ContractId
			,SUM(AppliedAmount) AS TotalAppliedAmount
		INTO #TotalAppliedAmount
		FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoices
		GROUP BY ContractId;


	WITH InvoiceBalanceAppliedAmount AS 
	(
		SELECT ContractId
			,InvoiceId
			,OriginalAmount
			,AgeInDays
			,DueDate
			,SUM(OriginalAmount) OVER (PARTITION BY contractid ORDER BY ContractId, DueDate) AS RunningContractCount
		FROM #AllInvoicesAfterMinimumDueDateOfOpenInvoices
	)

	UPDATE #DPDResult 
			SET OverallDPD = AgeInDays
		FROM 
		(
			SELECT contractid
				,invoiceid
				,AgeInDays
				,ROW_NUMBER() OVER (PARTITION BY contractid ORDER BY contractid, DueDate) AS [Rank]
			FROM 
			(
				SELECT InvoiceBalanceAppliedAmount.contractid AS contractid
					,InvoiceBalanceAppliedAmount.invoiceid AS invoiceid
					,InvoiceBalanceAppliedAmount.AgeInDays
					,InvoiceBalanceAppliedAmount.DueDate
					,#TotalAppliedAmount.TotalAppliedAmount - InvoiceBalanceAppliedAmount.RunningContractCount AS [difference]
				FROM InvoiceBalanceAppliedAmount
					INNER JOIN #TotalAppliedAmount ON InvoiceBalanceAppliedAmount.ContractId = #TotalAppliedAmount.ContractId
			) 
			aliasTable1
			WHERE [difference] < 0
		) 
		AllInvoiceAmountGreaterThanContractAppliedAmount
		WHERE AllInvoiceAmountGreaterThanContractAppliedAmount.[Rank] = 1 
			AND #DPDResult.ContractId = AllInvoiceAmountGreaterThanContractAppliedAmount.ContractId

	IF(@CustomerId = 0)
	BEGIN

		UPDATE ContractCollectionDetails 
			SET InterestDPD			= 0
				,RentOrPrincipalDPD = 0
				,MaturityDPD		= 0
				,OverallDPD			= 0
				,UpdatedById		= @UserId
				,UpdatedTime		= @ServerTimeStamp
		FROM ContractCollectionDetails
			INNER JOIN CollectionsJobContractExtracts ON ContractCollectionDetails.ContractId = CollectionsJobContractExtracts.ContractId
			INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
				ON CollectionsJobContractExtracts.LegalEntityId = AccessibleLegalEntities.LegalEntityId

	END
	ELSE
	BEGIN

		;WITH ContractsWithCustomer AS 
		(
			SELECT c.Id AS ContractId,
				CASE WHEN ContractType = 'Loan' OR ContractType = 'ProgressLoan' THEN loan.CustomerId
					WHEN ContractType = 'Lease' THEN lease.CustomerId
					WHEN ContractType = 'LeveragedLease' THEN leveragedLease.CustomerId
				END CustomerId
			FROM Contracts c
				LEFT JOIN LoanFinances loan ON c.Id = loan.ContractId
					AND loan.IsCurrent = 1
				LEFT JOIN LeaseFinances lease ON c.Id = lease.ContractId
					AND lease.IsCurrent = 1
				LEFT JOIN LeaseFinanceDetails leasefinancedetails ON leasefinancedetails.id = lease.id -- ?? need to remove, this is not required
				LEFT JOIN LeveragedLeases leveragedlease ON c.Id = leveragedlease.ContractId
					AND leveragedlease.IsCurrent = 1
		)


		UPDATE ContractCollectionDetails
			SET InterestDPD			= 0
				,RentOrPrincipalDPD = 0
				,MaturityDPD		= 0
				,OverallDPD			= 0
				,UpdatedById		= @UserId
				,UpdatedTime		= @ServerTimeStamp
			FROM ContractsWithCustomer 
				INNER JOIN ContractCollectionDetails ON ContractsWithCustomer.ContractId = ContractCollectionDetails.ContractId
			WHERE @CustomerId = 0 
				OR ContractsWithCustomer.CustomerId  = @CustomerId

	END


	MERGE ContractCollectionDetails
		USING #DPDResult
			ON #DPDResult.ContractId = ContractCollectionDetails.ContractId
		WHEN MATCHED THEN
			UPDATE SET  
				InterestDPD			= #DPDResult.InterestDPD
				,RentOrPrincipalDPD = #DPDResult.PrincipalDPD
				,MaturityDPD		= #DPDResult.MaturityDPD
				,OverallDPD			= #DPDResult.OverallDPD
				,UpdatedById		= @UserId
				,UpdatedTime		= @ServerTimeStamp
		WHEN NOT MATCHED BY TARGET THEN
			INSERT 
			(
				ContractId,
				OneToThirtyDaysLate,
				ThirtyPlusDaysLate,
				SixtyPlusDaysLate,
				NinetyPlusDaysLate,
				OneHundredTwentyPlusDaysLate,
			    LegacyZeroPlusDaysLate,
				LegacyThirtyPlusDaysLate,
				LegacySixtyPlusDaysLate,
				LegacyNinetyPlusDaysLate,
				LegacyOneHundredTwentyPlusDaysLate,
				TotalOneToThirtyDaysLate,
				TotalThirtyPlusDaysLate,
				TotalSixtyPlusDaysLate,
				TotalNinetyPlusDaysLate,
				TotalOneHundredTwentyPlusDaysLate,
				InterestDPD,
				RentOrPrincipalDPD,
				MaturityDPD,
				OverallDPD,
				CalculateDeliquencyDetails,
				CreatedById,
				CreatedTime
			) 
			VALUES 
			(
				#DPDResult.ContractId,
				0,    
				0, 
				0,    
				0,    
				0,
				0,
				0,
				0,
				0,
				0,
				0,  
				0,  
				0,  
				0,  
				0,
				#DPDResult.InterestDPD,
				#DPDResult.PrincipalDPD,
				#DPDResult.MaturityDPD,
				#DPDResult.OverallDPD,
				0,
				@UserId,
				@ServerTimeStamp
			);

END

GO
