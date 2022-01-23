SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FetchReceivableTaxJournalDataForAdjustment]
(
	@ReceivableIds ReceivableIdForReceivableTaxList READONLY
)
AS
BEGIN

SELECT
	ReceivableTaxGLs.ReceivableTaxId,
	MAX(ReceivableTaxGLs.Id) MaxReceivableTaxGLJournalId INTO #ReceivableTaxGLJournalInfo
FROM
	ReceivableTaxGLs
INNER JOIN ReceivableTaxes
	ON ReceivableTaxGLs.ReceivableTaxId = ReceivableTaxes.Id
INNER JOIN @ReceivableIds ReceivableIds
	ON ReceivableTaxes.ReceivableId = ReceivableIds.ReceivableId
WHERE 
	ReceivableTaxes.IsActive = 1 AND
	ReceivableTaxes.IsGLPosted = 1
GROUP BY
	ReceivableTaxGLs.ReceivableTaxId

	SELECT
		Contracts.Id EntityId
	   ,LeaseFinances.LegalEntityId
	   ,LeaseFinances.InstrumentTypeId
	   ,LeaseFinances.LineofBusinessId
	   ,LeaseFinances.CostCenterId
	   ,LeaseFinances.BranchId
	   ,Contracts.DealProductTypeId
	   ,Contracts.SequenceNumber
	   ,Parties.PartyNumber CustomerNumber
	   ,LegalEntities.CurrencyCode Currency
	   ,ReceivableTaxes.Id SourceId
	   ,Contracts.SyndicationType AS ContractSyndicationType
	   ,ReceivableTaxes.GLTemplateId
	   ,ReceivableCodes.Name ReceivableCodeName
	   ,Receivables.DueDate
	   ,ReceivableTaxes.Amount_Amount Amount
	   ,ReceivableTaxes.Balance_Amount Balance
	   ,Receivables.FunderId FunderId
	   ,ReceivableCodes.AccountingTreatment
	   ,LegalEntities.TaxRemittancePreference AS SalesTaxRemittancePreference
	   ,ReceivableForTransferFundingSources.SalesTaxResponsibility
	   ,ReceivableTypes.Name ReceivableType
	   ,Parties.IsIntercompany
	   ,ReceivableTaxGLs.GLJournalId

	   ,ReceivableCodes.SyndicationGLTemplateId 
	   ,Receivables.EntityType
	   ,Receivables.CustomerId
	   ,LeaseFinances.ContractId
	   ,Receivables.IsDSL
	   ,Contracts.ContractType
	   ,LeaseFinances.AcquisitionID AS AcquisitionId
	FROM ReceivableTaxes
	INNER JOIN @ReceivableIds ReceivableIds
		ON ReceivableIds.ReceivableId = ReceivableTaxes.ReceivableId
	INNER JOIN Receivables
		ON Receivables.Id = ReceivableTaxes.ReceivableId
	INNER JOIN Contracts
		ON Receivables.EntityId = Contracts.Id
	INNER JOIN LeaseFinances
		ON Contracts.Id = LeaseFinances.ContractId
			AND LeaseFinances.IsCurrent = 1
	INNER JOIN ReceivableCodes
		ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	INNER JOIN ReceivableTypes
		ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	INNER JOIN LegalEntities
		ON LeaseFinances.LegalEntityId = LegalEntities.Id
	INNER JOIN Parties
		ON LeaseFinances.CustomerId = Parties.Id
	INNER JOIN #ReceivableTaxGLJournalInfo
		ON ReceivableTaxes.Id = #ReceivableTaxGLJournalInfo.ReceivableTaxId
	INNER JOIN ReceivableTaxGLs
		ON #ReceivableTaxGLJournalInfo.MaxReceivableTaxGLJournalId = ReceivableTaxGLs.Id
	LEFT JOIN ReceivableForTransferFundingSources
		ON Receivables.FunderId = ReceivableForTransferFundingSources.FunderId

	WHERE ReceivableTaxes.IsActive = 1

END

GO
