SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[FetchReceivableJournalDataForAdjustment]
(
	@ReceivableIds ReceivableIdsList READONLY
)
AS
BEGIN

DECLARE @IsLoan bit
SET @IsLoan =0

SET @IsLoan = (Select count( c.Id) from Contracts c
INNER JOIN Receivables r on c.Id = r.EntityId
INNER JOIN @ReceivableIds RId ON r.Id = RId.ReceivableId
where c.ContractType = 'Loan' or c.ContractType = 'ProgressLoan')

SELECT
	ReceivableGLJournals.ReceivableId,
	MAX(ReceivableGLJournals.Id) MaxReceivableGLJournalId INTO #ReceivableGLJournalInfo
FROM
	ReceivableGLJournals
INNER JOIN @ReceivableIds ReceivableIds
	ON ReceivableGLJournals.ReceivableId = ReceivableIds.ReceivableId
GROUP BY
	ReceivableGLJournals.ReceivableId

	if(@IsLoan = 0)
	BEGIN
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
	   ,Receivables.Id SourceId
	   ,Contracts.SyndicationType
	   ,ReceivableCodes.GLTemplateId
	   ,ReceivableCodes.Name ReceivableCodeName
	   ,Receivables.DueDate
	   ,Receivables.TotalAmount_Amount Amount
	   ,Receivables.TotalBalance_Amount Balance
	   ,Receivables.FunderId FunderId
	   ,ReceivableCodes.AccountingTreatment
	   ,ReceivableTypes.Name ReceivableType
	   ,Parties.IsIntercompany
	   ,ReceivableGLJournals.GLJournalId

	   ,ReceivableCodes.SyndicationGLTemplateId 
	   ,Receivables.EntityType
	   ,Receivables.CustomerId
	   ,LeaseFinances.ContractId
	   ,Receivables.IsDSL
	   ,Contracts.ContractType
	   ,LeaseFinances.AcquisitionID AS AcquisitionId
	FROM Receivables
	INNER JOIN @ReceivableIds ReceivableIds
		ON ReceivableIds.ReceivableId = Receivables.Id
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
	INNER JOIN #ReceivableGLJournalInfo
		ON Receivables.Id = #ReceivableGLJournalInfo.ReceivableId
	INNER JOIN ReceivableGLJournals
		ON #ReceivableGLJournalInfo.MaxReceivableGLJournalId = ReceivableGLJournals.Id
		END

		ELSE
		BEGIN
		SELECT
		Contracts.Id EntityId
	   ,LoanFinances.LegalEntityId
	   ,LoanFinances.InstrumentTypeId
	   ,LoanFinances.LineofBusinessId
	   ,LoanFinances.CostCenterId
	   ,LoanFinances.BranchId
	   ,Contracts.DealProductTypeId
	   ,Contracts.SequenceNumber
	   ,Parties.PartyNumber CustomerNumber
	   ,LegalEntities.CurrencyCode Currency
	   ,Receivables.Id SourceId
	   ,Contracts.SyndicationType
	   ,ReceivableCodes.GLTemplateId
	   ,ReceivableCodes.Name ReceivableCodeName
	   ,Receivables.DueDate
	   ,Receivables.TotalAmount_Amount Amount
	   ,Receivables.TotalBalance_Amount Balance
	   ,Receivables.FunderId FunderId
	   ,ReceivableCodes.AccountingTreatment
	   ,ReceivableTypes.Name ReceivableType
	   ,Parties.IsIntercompany
	   ,ReceivableGLJournals.GLJournalId

	   ,ReceivableCodes.SyndicationGLTemplateId 
	   ,Receivables.EntityType
	   ,Receivables.CustomerId
	   ,LoanFinances.ContractId
	   ,LoanFinances.LoanBookingGLTemplateId AS BookingGLTemplateId
	   ,Receivables.IsDSL
	   ,Contracts.ContractType
	   ,LoanFinances.AcquisitionID AS AcquisitionId
	   ,LoanFinances.CommencementDate
	   ,LoanFinances.LoanIncomeRecognitionGLTemplateId AS IncomeRecognitionGLTemplateId
	   ,LoanFinances.InterimIncomeRecognitionGLTemplateId
	FROM Receivables
	INNER JOIN @ReceivableIds ReceivableIds
		ON ReceivableIds.ReceivableId = Receivables.Id
	INNER JOIN Contracts
		ON Receivables.EntityId = Contracts.Id
	INNER JOIN LoanFinances
		ON Contracts.Id = LoanFinances.ContractId
			AND LoanFinances.IsCurrent = 1
	INNER JOIN ReceivableCodes
		ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	INNER JOIN ReceivableTypes
		ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	INNER JOIN LegalEntities
		ON LoanFinances.LegalEntityId = LegalEntities.Id
	INNER JOIN Parties
		ON LoanFinances.CustomerId = Parties.Id
	INNER JOIN #ReceivableGLJournalInfo
		ON Receivables.Id = #ReceivableGLJournalInfo.ReceivableId
	INNER JOIN ReceivableGLJournals
		ON #ReceivableGLJournalInfo.MaxReceivableGLJournalId = ReceivableGLJournals.Id
		END

END

GO
