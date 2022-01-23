SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateTimesLateCounter] 
(
	@JobStepInstanceId			BIGINT
	,@CustomerId				BIGINT
	,@UpdateThroughDate			DATETIME
	,@EntityTypeCT				NVARCHAR(2)	
	,@ReceivableCategoryPayoff	NVARCHAR(16)
	,@ReceivableCategoryAssetSale NVARCHAR(16) 
	,@ReceivableCategoryPaydown NVARCHAR(16)
	,@UserId					BIGINT
	,@ServerTimeStamp			DATETIMEOFFSET
	,@AccessibleLegalEntities UpdateTimesLateLegalEntityId READONLY
)
AS
BEGIN
    -- Reset and Update ContractCollectionDetails.OneToThirtyDaysLate, ThirtyPlusDaysLate, SixtyPlusDaysLate, NinetyPlusDaysLate, OneHundredTwentyPlusDaysLate Columns
	-- Update ReceivableInvoiceDeliquencyDetails.IsOneToThirtyDaysLate, IsThirtyPlusDaysLate, IsSixtyPlusDaysLate, IsNinetyPlusDaysLate, IsOneHundredTwentyPlusDaysLate columns
	-- Update Receivableinvoices.DaysLateCount
	SET NOCOUNT ON;

	SELECT *
		INTO #AgeInDays
		FROM 
		(
			SELECT ReceivableInvoices.Id AS InvoiceId
				,ReceivableInvoices.CustomerId
				,ReceivableInvoiceDetails.EntityID AS ContractId
				,ReceivableInvoices.CreatedTime
				,DATEDIFF(DD, DATEADD(DAY, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate), @UpdateThroughDate) AS AgeInDays
			FROM CollectionsJobExtracts
				INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.EntityId = CollectionsJobExtracts.ContractId 
					    AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT 
					    AND ReceivableInvoiceDetails.IsActive = 1
				INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
					AND CollectionsJobExtracts.CustomerId = ReceivableInvoices.CustomerId
					AND ReceivableInvoices.IsActive = 1
				INNER JOIN LegalEntities ON LegalEntities.Id = ReceivableInvoices.LegalEntityId
				INNER JOIN Receivablecategories ON Receivablecategories.id = ReceivableInvoices.ReceivablecategoryId
			WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
				AND (ReceivableInvoices.IsDummy = 0 OR (ReceivableInvoices.IsDummy = 1 AND Receivablecategories.Name NOT IN (@ReceivableCategoryPayoff, @ReceivableCategoryAssetSale, @ReceivableCategoryPaydown)))
				AND ReceivableInvoices.DueDate <= @UpdateThroughDate
				AND (ReceivableInvoiceDetails.Balance_Amount > 0 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0)
			GROUP BY ReceivableInvoices.Id, ReceivableInvoices.CustomerId, ReceivableInvoiceDetails.EntityID, ReceivableInvoices.CreatedTime, ReceivableInvoices.DueDate, LegalEntities.ThresholdDays
		) 
		AllOpenInvoices
		WHERE AgeInDays > 0

	CREATE INDEX IX_AgeInDays_InvoiceId_ContractId ON #AgeInDays(InvoiceId, ContractId);

	UPDATE Receivableinvoices
			SET DaysLateCount = #AgeInDays.AgeInDays
		FROM #AgeInDays
		WHERE #AgeInDays.InvoiceId = Receivableinvoices.Id 


	;WITH DeliquentInvoices AS 
		(
			SELECT invoiceid, 
					MAX(AgeInDays) AS AgeInDays 
				FROM #AgeInDays GROUP BY InvoiceId
		)

	MERGE ReceivableInvoiceDeliquencyDetails
		USING DeliquentInvoices
			ON DeliquentInvoices.InvoiceId = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId
		WHEN MATCHED THEN
			UPDATE
				SET IsOneToThirtyDaysLate = CASE WHEN IsOneToThirtyDaysLate = 1 THEN 1 WHEN AgeInDays > 0 THEN 1 ELSE 0 END
					,IsThirtyPlusDaysLate = CASE WHEN IsThirtyPlusDaysLate = 1 THEN 1 WHEN AgeInDays > 30 THEN 1 ELSE 0 END
					,IsSixtyPlusDaysLate = CASE WHEN IsSixtyPlusDaysLate = 1 THEN 1 WHEN AgeInDays > 60 THEN 1 ELSE 0 END
					,IsNinetyPlusDaysLate = CASE WHEN IsNinetyPlusDaysLate = 1 THEN 1 WHEN AgeInDays > 90 THEN 1 ELSE 0 END
					,IsOneHundredTwentyPlusDaysLate = CASE WHEN IsOneHundredTwentyPlusDaysLate = 1 THEN 1 WHEN AgeInDays > 120 THEN 1 ELSE 0 END
					,UpdatedById = @UserId
					,UpdatedTime = @ServerTimeStamp
		WHEN NOT MATCHED BY TARGET THEN
			INSERT 
			(
				ReceivableInvoiceId
				,IsOneToThirtyDaysLate
				,IsThirtyPlusDaysLate
				,IsSixtyPlusDaysLate
				,IsNinetyPlusDaysLate
				,IsOneHundredTwentyPlusDaysLate
				,CreatedById
				,CreatedTime
			)
			VALUES 
			(
				DeliquentInvoices.InvoiceId
				,CASE WHEN AgeInDays > 0 THEN 1 ELSE 0 END
				,CASE WHEN AgeInDays > 30 THEN 1 ELSE 0 END
				,CASE WHEN AgeInDays > 60 THEN 1 ELSE 0 END
				,CASE WHEN AgeInDays > 90 THEN 1 ELSE 0 END
				,CASE WHEN AgeInDays > 120 THEN 1 ELSE 0 END
				,@UserId
				,@ServerTimeStamp
			);

	SELECT ContractId
			,SUM(CASE WHEN AgeInDays > 0 AND AgeInDays <= 30 THEN 1 ELSE 0 END) AS OneToThirtyCount
			,SUM(CASE WHEN AgeInDays > 30 AND AgeInDays <= 60 THEN 1 ELSE 0 END) AS ThirtyPlusDaysCount
			,SUM(CASE WHEN AgeInDays > 60 AND AgeInDays <= 90 THEN 1 ELSE 0 END) AS SixtyPlusDaysCount
			,SUM(CASE WHEN AgeInDays > 90 AND AgeInDays <= 120 THEN 1 ELSE 0 END) AS NinetyPlusDaysCount
			,SUM(CASE WHEN AgeInDays > 120 THEN 1 ELSE 0 END) AS OnehunderedTwentyPlusDaysCount
		INTO #InvoiceBuckets
		FROM #AgeInDays 
		GROUP BY #AgeInDays.ContractId

	

	IF (@CustomerId = 0)
	BEGIN

		UPDATE ContractCollectionDetails
			SET OneToThirtyDaysLate = 0
				,ThirtyPlusDaysLate = 0
				,SixtyPlusDaysLate = 0
				,NinetyPlusDaysLate = 0
				,OneHundredTwentyPlusDaysLate = 0
				,UpdatedById = @UserId
				,UpdatedTime = @ServerTimeStamp
			FROM ContractCollectionDetails
				INNER JOIN CollectionsJobContractExtracts 
					ON ContractCollectionDetails.ContractId = CollectionsJobContractExtracts.ContractId
				INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
					ON CollectionsJobContractExtracts.LegalEntityId = AccessibleLegalEntities.LegalEntityId

	END
	ELSE
	BEGIN

		;WITH ContractsWithCustomer AS 
		(
			SELECT c.Id AS ContractId
				,CASE WHEN ContractType = 'Loan' THEN loan.CustomerId 
					WHEN ContractType = 'Lease' THEN lease.CustomerId 
					WHEN ContractType = 'LeveragedLease' THEN leveragedLease.CustomerId 
				END CustomerId
			FROM Contracts c
				LEFT JOIN LoanFinances loan ON c.Id = loan.ContractId
					AND loan.IsCurrent = 1
				LEFT JOIN LeaseFinances lease ON c.Id = lease.ContractId
					AND lease.IsCurrent = 1
				LEFT JOIN LeaseFinanceDetails leasefinancedetails ON leasefinancedetails.id = lease.id
				LEFT JOIN LeveragedLeases leveragedlease ON c.Id = leveragedlease.ContractId
					AND leveragedlease.IsCurrent = 1
		)


		UPDATE ContractCollectionDetails
			SET OneToThirtyDaysLate = 0
				,ThirtyPlusDaysLate = 0
				,SixtyPlusDaysLate = 0
				,NinetyPlusDaysLate = 0
				,OneHundredTwentyPlusDaysLate = 0
				,UpdatedById = @UserId
				,UpdatedTime = @ServerTimeStamp
			FROM ContractsWithCustomer
				INNER JOIN ContractCollectionDetails ON ContractsWithCustomer.ContractId = ContractCollectionDetails.ContractId
			WHERE ContractsWithCustomer.CustomerId = @CustomerId

	END

	MERGE ContractCollectionDetails
		USING #InvoiceBuckets
			ON #InvoiceBuckets.ContractId = ContractCollectionDetails.ContractId
		WHEN MATCHED THEN
			UPDATE
				SET  OneToThirtyDaysLate = #InvoiceBuckets.OneToThirtyCount
					,ThirtyPlusDaysLate = #InvoiceBuckets.ThirtyPlusDaysCount
					,SixtyPlusDaysLate = #InvoiceBuckets.SixtyPlusDaysCount
					,NinetyPlusDaysLate = #InvoiceBuckets.NinetyPlusDaysCount
					,OneHundredTwentyPlusDaysLate = #InvoiceBuckets.OnehunderedTwentyPlusDaysCount
					,UpdatedById = @UserId
					,UpdatedTime = @ServerTimeStamp
		WHEN NOT MATCHED BY TARGET THEN
			INSERT 
			(
				ContractId
				,OneToThirtyDaysLate
				,ThirtyPlusDaysLate
				,SixtyPlusDaysLate
				,NinetyPlusDaysLate
				,OneHundredTwentyPlusDaysLate
				,LegacyZeroPlusDaysLate
				,LegacyThirtyPlusDaysLate
				,LegacySixtyPlusDaysLate
				,LegacyNinetyPlusDaysLate
				,LegacyOneHundredTwentyPlusDaysLate
				,TotalOneToThirtyDaysLate
				,TotalThirtyPlusDaysLate
				,TotalSixtyPlusDaysLate
				,TotalNinetyPlusDaysLate
				,TotalOneHundredTwentyPlusDaysLate
				,InterestDPD
				,RentOrPrincipalDPD
				,MaturityDPD
				,OverallDPD
				,CalculateDeliquencyDetails
				,CreatedById
				,CreatedTime
			)
			VALUES 
			(
				#InvoiceBuckets.ContractId
				,#InvoiceBuckets.OneToThirtyCount
				,#InvoiceBuckets.ThirtyPlusDaysCount
				,#InvoiceBuckets.SixtyPlusDaysCount
				,#InvoiceBuckets.NinetyPlusDaysCount
				,#InvoiceBuckets.OnehunderedTwentyPlusDaysCount
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,@UserId
				,@ServerTimeStamp
			);


	SELECT ContractCollectionDetails.ContractId 
		INTO #CancelledInvoiceContracts 
		FROM ContractCollectionDetails 
			INNER JOIN CollectionsJobContractExtracts 
				ON ContractCollectionDetails.ContractId = CollectionsJobContractExtracts.ContractId
			INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
				ON CollectionsJobContractExtracts.LegalEntityId = AccessibleLegalEntities.LegalEntityId
		WHERE ContractCollectionDetails.CalculateDeliquencyDetails = 1 


	;WITH DeliquentContracts AS 
		(
			SELECT ContractId FROM #AgeInDays GROUP BY ContractId
			UNION
			SELECT ContractId FROM #CancelledInvoiceContracts
		),
	InvoiceOfDeliquentContracts AS 
		(
			SELECT DeliquentContracts.ContractId, 
				ReceivableInvoices.Id AS ReceivableInvoiceId
			FROM  ReceivableInvoices
				INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId and ReceivableInvoices.IsActive = 1
				INNER JOIN DeliquentContracts ON ReceivableInvoiceDetails.EntityId = DeliquentContracts.ContractId 
					AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT
			GROUP BY DeliquentContracts.ContractId, ReceivableInvoices.Id 
		),
	ContractsWithDeliquentDetails AS 
		(
			SELECT InvoiceOfDeliquentContracts.ContractId
				,SUM(IsOneToThirtyDaysLate * 1) AS TotalOneToThirtyCount
				,SUM(IsThirtyPlusDaysLate * 1) AS TotalThirtyPlusDaysCount
				,SUM(IsSixtyPlusDaysLate * 1) AS TotalSixtyPlusDaysCount
				,SUM(IsNinetyPlusDaysLate * 1) AS TotalNinetyPlusDaysCount
				,SUM(IsOneHundredTwentyPlusDaysLate * 1) AS TotalOnehunderedTwentyPlusDaysCount
			FROM ReceivableInvoiceDeliquencyDetails
				INNER JOIN InvoiceOfDeliquentContracts ON ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId = InvoiceOfDeliquentContracts.ReceivableInvoiceId
			GROUP BY InvoiceOfDeliquentContracts.ContractId
		)
	
	UPDATE ContractCollectionDetails
		SET TotalOneToThirtyDaysLate = LegacyZeroPlusDaysLate + ContractsWithDeliquentDetails.TotalOneToThirtyCount
			,TotalThirtyPlusDaysLate = LegacyThirtyPlusDaysLate + ContractsWithDeliquentDetails.TotalThirtyPlusDaysCount
			,TotalSixtyPlusDaysLate = LegacySixtyPlusDaysLate + ContractsWithDeliquentDetails.TotalSixtyPlusDaysCount
			,TotalNinetyPlusDaysLate = LegacyNinetyPlusDaysLate + ContractsWithDeliquentDetails.TotalNinetyPlusDaysCount
			,TotalOneHundredTwentyPlusDaysLate = LegacyOneHundredTwentyPlusDaysLate + ContractsWithDeliquentDetails.TotalOnehunderedTwentyPlusDaysCount
			,CalculateDeliquencyDetails = 0
			,UpdatedById = @UserId
			,UpdatedTime = @ServerTimeStamp
		FROM ContractCollectionDetails
			INNER JOIN ContractsWithDeliquentDetails ON ContractCollectionDetails.ContractId = ContractsWithDeliquentDetails.ContractId
		
	UPDATE ContractCollectionDetails 
		SET TotalOneToThirtyDaysLate = LegacyZeroPlusDaysLate
			,TotalThirtyPlusDaysLate = LegacyThirtyPlusDaysLate
			,TotalSixtyPlusDaysLate = LegacySixtyPlusDaysLate
			,TotalNinetyPlusDaysLate = LegacyNinetyPlusDaysLate
			,TotalOneHundredTwentyPlusDaysLate = LegacyOneHundredTwentyPlusDaysLate
			,CalculateDeliquencyDetails = 0
		FROM ContractCollectionDetails 
			INNER JOIN #CancelledInvoiceContracts ON ContractCollectionDetails.ContractId = #CancelledInvoiceContracts.ContractId
		WHERE ContractCollectionDetails.CalculateDeliquencyDetails = 1


	DROP TABLE #AgeInDays;

END

GO
