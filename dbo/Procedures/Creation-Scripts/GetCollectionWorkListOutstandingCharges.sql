SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCollectionWorkListOutstandingCharges]
(
	 @CollectionWorkListId BIGINT
	,@CurrentDate DATE
	,@EntityTypeCT NVARCHAR(2)
	,@InterimInterestIncomeType NVARCHAR(16)
	,@TakeDownInterestIncomeType NVARCHAR(16)
	,@AccessibleLegalEntities WaiverLegalEntityId READONLY
	,@LeaseContractType  NVARCHAR(14)
	,@LoanContractType NVARCHAR(14)
	,@ProgressLoanContractType NVARCHAR(14)
)
AS
BEGIN
		SELECT DISTINCT
			CollectionWorkListContractDetails.ContractId,
			CollectionWorkLists.CustomerId,
			CollectionWorkLists.RemitToId
		INTO #WorkListContracts
		FROM CollectionWorkLists
			INNER JOIN CollectionWorkListContractDetails 
				ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
		WHERE CollectionWorkLists.Id = @CollectionWorkListId
			  AND CollectionWorkListContractDetails.IsWorkCompleted = 0

		DECLARE
@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )

		SELECT 
			ReceivableInvoiceDetails.ReceivableInvoiceId,
			ReceivableInvoiceDetails.ReceivableId,
			SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount +
			ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) OutstandingAmount_Amount,
			Receivables.LegalEntityId,
			LegalEntities.LegalEntityNumber,
			ReceivableInvoices.Number AS InvoiceNumber,
			ReceivableCodes.Name AS ReceivableCodeName,
			ReceivableTypes.Name AS ReceivableTypeName,
			Receivables.DueDate,
			CASE WHEN Contracts.ContractType = @LeaseContractType THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END AS InstrumentTypeId,    
			CASE WHEN Contracts.ContractType = @LeaseContractType THEN LeaseFinances.LineofBusinessId ELSE LoanFinances.LineofBusinessId END AS LineofBusinessId,    
			CASE WHEN Contracts.ContractType = @LeaseContractType THEN LeaseFinances.CostCenterId ELSE LoanFinances.CostCenterId END AS CostCenterId,    
			CASE WHEN Contracts.ContractType = @LeaseContractType THEN LeaseFinances.BranchId ELSE LoanFinances.BranchId END AS BranchId    
		FROM 
			ReceivableInvoices
		INNER JOIN ReceivableInvoiceDetails
			ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
			AND ReceivableInvoices.IsActive = 1
			AND ReceivableInvoiceDetails.IsActive = 1
			AND ReceivableInvoices.IsDummy = 0   				
		INNER JOIN #WorkListContracts AS WLC 
			ON ReceivableInvoiceDetails.EntityId = WLC.ContractId
			AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT	
			AND ReceivableInvoices.CustomerId = WLC.CustomerId
		INNER JOIN Receivables
			ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id
			AND Receivables.IsActive = 1
			AND Receivables.IsDummy = 0   
			AND Receivables.IsCollected = 1
		INNER JOIN ReceivableCodes
			ON Receivables.ReceivableCodeId = ReceivableCodes.Id 
		INNER JOIN ReceivableTypes
			ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
		INNER JOIN LegalEntities 
			ON LegalEntities.Id = Receivables.LegalEntityId
		INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
			ON LegalEntities.Id = AccessibleLegalEntities.Id
		INNER JOIN Contracts 
			ON Receivables.EntityId = Contracts.Id 
		LEFT JOIN LeaseFinances 
			ON Contracts.ContractType = @LeaseContractType 
			AND LeaseFinances.ContractId = Contracts.Id 
			AND LeaseFinances.IsCurrent = 1    
		LEFT JOIN LoanFinances ON 
			(Contracts.ContractType = @LoanContractType OR Contracts.ContractType = @ProgressLoanContractType) 
			AND LoanFinances.ContractId = Contracts.Id 
			AND LoanFinances.IsCurrent = 1 			
		WHERE
			(
				-- To fetch records belonging to worklist remit to
				(WLC.RemitToId IS NOT NULL AND WLC.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
				OR (WLC.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
			)
			AND DATEADD(day, LegalEntities.ThresholdDays, ReceivableInvoices.DueDate) <= @CurrentDate AND 
			(ReceivableInvoiceDetails.EffectiveBalance_Amount > 0 OR ReceivableInvoiceDetails.EffectiveTaxBalance_Amount > 0)
			AND ((Contracts.ContractType != @LoanContractType OR Contracts.IsNonAccrual = 0)
		OR (ReceivableTypes.Id != @LoanInterestReceivableTypeId AND ReceivableTypes.Id != @LoanPrincipalReceivableTypeId)
		OR (Receivables.IncomeType IN (@InterimInterestIncomeType,@TakeDownInterestIncomeType))) 
		GROUP BY 
			ReceivableInvoiceDetails.ReceivableInvoiceId,
			ReceivableInvoiceDetails.ReceivableId,
			Receivables.LegalEntityId,
			LegalEntities.LegalEntityNumber,
			ReceivableInvoices.Number,
			ReceivableCodes.Name,
			ReceivableTypes.Name,
			Receivables.DueDate, 
			Contracts.ContractType,
			LeaseFinances.InstrumentTypeId,
			LoanFinances.InstrumentTypeId,
			LeaseFinances.LineofBusinessId,
			LoanFinances.LineofBusinessId,
			LeaseFinances.CostCenterId,
			LoanFinances.CostCenterId,
			LeaseFinances.BranchId,
			LoanFinances.BranchId

		DROP TABLE #WorkListContracts

END

GO
