SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CalculateDaysPastDueWithoutRentShift]
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
	,@AccessibleLegalEntities CalculateDPDWithoutShiftLegalEntityId READONLY
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
				,DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate), @UpdateThroughDate) AS AgeInDays
			FROM CollectionsJobExtracts
				INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.EntityType = @EntityTypeCT 
					AND ReceivableInvoiceDetails.EntityId = CollectionsJobExtracts.ContractId 
					AND ReceivableInvoiceDetails.IsActive = 1
				INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
					AND CollectionsJobExtracts.CustomerId = ReceivableInvoices.CustomerId 
					AND ReceivableInvoices.IsActive = 1 
				INNER JOIN LegalEntities ON LegalEntities.Id = ReceivableInvoices.LegalEntityId
				INNER JOIN Receivablecategories ON ReceivableInvoices.ReceivablecategoryId = Receivablecategories.id
			WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
				AND (ReceivableInvoices.IsDummy = 0 OR (ReceivableInvoices.IsDummy = 1 AND Receivablecategories.Name NOT IN (@ReceivableCategoryPayoff, @ReceivableCategoryAssetSale, @ReceivableCategoryPaydown)))
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
		GROUP BY #OpenDueDayPastInvoices.ContractId;

	--Interest DPD
	UPDATE #DPDResult 
			SET #DPDResult.InterestDPD = alias.InterestDPD
		FROM 
		(
			SELECT #OpenDueDayPastInvoices.ContractId AS ContractId
				,MAX(#OpenDueDayPastInvoices.AgeInDays) InterestDPD
			FROM #OpenDueDayPastInvoices
			WHERE Exists
				(
					SELECT * FROM ReceivableInvoiceDetails
						INNER JOIN ReceivableTypes ON ReceivableInvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
					WHERE ReceivableInvoiceDetails.ReceivableInvoiceId = #OpenDueDayPastInvoices.InvoiceId
						AND ReceivableInvoiceDetails.EntityId = #OpenDueDayPastInvoices.ContractId
						AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT
						AND ReceivableTypes.Name IN ('LoanInterest', 'LeaseFloatRateAdj', 'LeaseInterimInterest')
				)
			GROUP BY #OpenDueDayPastInvoices.ContractId 
		) 
		alias 
		WHERE alias.ContractId = #DPDResult.ContractId


	--Maturity DPD
	UPDATE #DPDResult 
			SET #DPDResult.MaturityDPD = alias.MaturityDPD
		FROM 
		(
			SELECT #OpenDueDayPastInvoices.ContractId AS ContractId
				,MAX(#OpenDueDayPastInvoices.AgeInDays) MaturityDPD
			FROM #OpenDueDayPastInvoices
			WHERE EXISTS
				(
					SELECT * FROM ReceivableInvoiceDetails
						INNER JOIN ReceivableTypes ON ReceivableInvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
					WHERE ReceivableInvoiceDetails.ReceivableInvoiceId = #OpenDueDayPastInvoices.InvoiceId
						AND ReceivableInvoiceDetails.EntityId = #OpenDueDayPastInvoices.ContractId
						AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT
						AND ReceivableTypes.Name IN ('OverTermRental', 'Supplemental')
				)
			GROUP BY #OpenDueDayPastInvoices.ContractId 
		) 
		alias 
		WHERE alias.ContractId = #DPDResult.ContractId


	--Principal DPD
	UPDATE #DPDResult 
			SET #DPDResult.PrincipalDPD = alias.PrincipalDPD
		FROM 
		(
			SELECT #OpenDueDayPastInvoices.ContractId AS ContractId
				,MAX(#OpenDueDayPastInvoices.AgeInDays) PrincipalDPD
			FROM #OpenDueDayPastInvoices
			WHERE EXISTS
				(
					SELECT * from ReceivableInvoiceDetails
						INNER JOIN ReceivableTypes ON ReceivableInvoiceDetails.ReceivableTypeId = ReceivableTypes.Id
					WHERE ReceivableInvoiceDetails.ReceivableInvoiceId = #OpenDueDayPastInvoices.InvoiceId
						AND ReceivableInvoiceDetails.EntityId = #OpenDueDayPastInvoices.ContractId
						AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT 
						AND ReceivableTypes.Name IN ('CPIBaseRental', 'CPIOverage', 'CapitalLeaseRental', 'InterimRental', 'LeaseFloatRateAdj', 'LeveragedLeaseRental', 'LoanPrincipal', 'OperatingLeaseRental')
				)
			GROUP BY #OpenDueDayPastInvoices.ContractId 
		) 
		alias 
		WHERE alias.ContractId = #DPDResult.ContractId


	--Overall DPD
	UPDATE #DPDResult 
			SET #DPDResult.OverallDPD = alias.OverallDPD
		FROM 
		(
			SELECT #OpenDueDayPastInvoices.ContractId AS ContractId
				,MAX(#OpenDueDayPastInvoices.AgeInDays) OverallDPD
			FROM #OpenDueDayPastInvoices
			GROUP BY #OpenDueDayPastInvoices.ContractId 
		) 
		alias 
		WHERE alias.ContractId = #DPDResult.ContractId


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
					CASE WHEN ContractType = 'Loan' OR  ContractType = 'ProgressLoan' THEN loan.CustomerId
						WHEN ContractType = 'Lease' THEN lease.CustomerId
						WHEN ContractType = 'LeveragedLease' THEN leveragedLease.CustomerId
					END CustomerId
				FROM Contracts c
					LEFT JOIN LoanFinances loan ON c.Id = loan.ContractId
						AND loan.IsCurrent = 1
					LEFT JOIN LeaseFinances lease ON c.Id = lease.ContractId
						AND lease.IsCurrent = 1
					LEFT JOIN LeaseFinanceDetails leasefinancedetails ON leasefinancedetails.id = lease.id  -- ?? need to remove, this is not required
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
			WHERE ContractsWithCustomer.CustomerId  = @CustomerId

	END


	MERGE ContractCollectionDetails
		USING #DPDResult
			ON #DPDResult.ContractId = ContractCollectionDetails.ContractId
		WHEN MATCHED THEN
			UPDATE SET InterestDPD	= #DPDResult.InterestDPD
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
