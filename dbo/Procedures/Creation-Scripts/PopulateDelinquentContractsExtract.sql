SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PopulateDelinquentContractsExtract]
(
	 @JobStepInstanceId			BIGINT
	,@BusinessUnitId			BIGINT
    ,@CustomerId				BIGINT
	,@UpdateThroughDate			DATETIME
	,@EntityTypeCT				NVARCHAR(2)
	,@ReceivableCategoryPayoff	NVARCHAR(16)
	,@ReceivableCategoryAssetSale NVARCHAR(16) 
	,@ReceivableCategoryPaydown	NVARCHAR(16)
	,@UserId					BIGINT
	,@ServerTimeStamp			DATETIMEOFFSET
	,@AccessibleLegalEntities CollectionsLegalEntityId READONLY
)
AS
BEGIN
 
	CREATE TABLE #ContractsLegalEntity
	(
		ContractId BIGINT NOT NULL,
		LegalEntityId BIGINT NOT NULL
	)

	INSERT INTO #ContractsLegalEntity (ContractId, LegalEntityId)
		SELECT DISTINCT Contracts.Id ContractId, LeaseFinances.LegalEntityId
			FROM Contracts 
				INNER JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
				INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities ON LeaseFinances.LegalEntityId = AccessibleLegalEntities.LegalEntityId
			WHERE (@CustomerId = 0 OR LeaseFinances.CustomerId = @CustomerId)

	INSERT INTO #ContractsLegalEntity (ContractId, LegalEntityId)
		SELECT DISTINCT Contracts.Id ContractId, LoanFinances.LegalEntityId
			FROM Contracts 
				INNER JOIN LoanFinances ON LoanFinances.ContractId = Contracts.Id AND LoanFinances.IsCurrent = 1
				INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities ON LoanFinances.LegalEntityId = AccessibleLegalEntities.LegalEntityId
		WHERE (@CustomerId = 0 OR LoanFinances.CustomerId = @CustomerId)


	INSERT INTO #ContractsLegalEntity (ContractId, LegalEntityId)
		SELECT DISTINCT Contracts.Id ContractId, LeveragedLeases.LegalEntityId
			FROM Contracts 
				INNER JOIN LeveragedLeases ON LeveragedLeases.ContractId = Contracts.Id AND LeveragedLeases.IsCurrent = 1
				INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities ON LeveragedLeases.LegalEntityId = AccessibleLegalEntities.LegalEntityId
		WHERE (@CustomerId = 0 OR LeveragedLeases.CustomerId = @CustomerId)
		

	MERGE CollectionsJobContractExtracts
			USING #ContractsLegalEntity
				ON CollectionsJobContractExtracts.ContractId = #ContractsLegalEntity.ContractId
		WHEN MATCHED THEN
			UPDATE SET 
				LegalEntityId = #ContractsLegalEntity.LegalEntityId,
				UpdatedById = @UserId,
				UpdatedTime = @ServerTimeStamp
		WHEN NOT MATCHED BY TARGET THEN
			INSERT 
				(
					ContractId,
					LegalEntityId,
					CreatedById,
					CreatedTime
				) 
			VALUES 
				(
					#ContractsLegalEntity.ContractId,
					#ContractsLegalEntity.LegalEntityId,
					@UserId,
					@ServerTimeStamp
				);
					

	INSERT INTO CollectionsJobExtracts
	(
		ContractId,
		CustomerId,
		CurrencyId,
		RemitToId,
		BusinessUnitId,
		JobStepInstanceId,
		CreatedById,
		CreatedTime,
		IsWorkListIdentified,
		IsWorkListCreated,
		IsWorkListUnassigned,
		AcrossQueue
	)
	SELECT	 
			DISTINCT
				Contracts.Id ContractId,
				ReceivableInvoices.CustomerId,
				Currencies.Id,
				CASE WHEN ReceivableInvoices.IsPrivateLabel = 1 THEN ReceivableInvoices.RemitToId ELSE NULL END RemitToId,
				@BusinessUnitId,
				@JobStepInstanceId,
				@UserId,
				@ServerTimeStamp,
				0,
				0,
				0,
				0	
		FROM
				Contracts
			INNER JOIN Currencies
				ON Contracts.CurrencyId = Currencies.Id
			INNER JOIN ReceivableInvoiceDetails
				ON ReceivableInvoiceDetails.EntityType = @EntityTypeCT AND 
				   ReceivableInvoiceDetails.EntityId = Contracts.Id AND
				   ReceivableInvoiceDetails.IsActive = 1
			INNER JOIN ReceivableInvoices
				ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND
				   ReceivableInvoices.IsActive = 1 
			INNER JOIN Receivablecategories 
				On ReceivableInvoices.ReceivablecategoryId = Receivablecategories.id 
			INNER JOIN Customers
				ON ReceivableInvoices.CustomerId = Customers.Id
			INNER JOIN CollectionsJobContractExtracts
				ON Contracts.Id = CollectionsJobContractExtracts.ContractId
			INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
				ON CollectionsJobContractExtracts.LegalEntityId = AccessibleLegalEntities.LegalEntityId
			INNER JOIN LegalEntities ON LegalEntities.Id = AccessibleLegalEntities.LegalEntityId
			WHERE
				(ReceivableInvoices.IsDummy = 0 OR (ReceivableInvoices.IsDummy = 1 AND Receivablecategories.Name NOT IN (@ReceivableCategoryPayoff, @ReceivableCategoryAssetSale, @ReceivableCategoryPaydown))) AND
				DATEADD(day, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate) <= @UpdateThroughDate AND 
				(ReceivableInvoiceDetails.Balance_Amount > 0 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0) AND
				(@CustomerId = 0 OR ReceivableInvoices.CustomerId = @CustomerId)

END

GO
