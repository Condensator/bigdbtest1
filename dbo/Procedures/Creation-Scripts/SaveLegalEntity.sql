SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLegalEntity]
(
 @val [dbo].[LegalEntity] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[LegalEntities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingStandard]=S.[AccountingStandard],[ACHFailureLimit]=S.[ACHFailureLimit],[ActivationDate]=S.[ActivationDate],[BusinessCalendarId]=S.[BusinessCalendarId],[BusinessTypeId]=S.[BusinessTypeId],[BusinessUnitId]=S.[BusinessUnitId],[CostCenter]=S.[CostCenter],[CurrencyCode]=S.[CurrencyCode],[CurrencyId]=S.[CurrencyId],[DeactivationDate]=S.[DeactivationDate],[FiscalYearBeginMonthNo]=S.[FiscalYearBeginMonthNo],[GLAccountNumber]=S.[GLAccountNumber],[GLConfigurationId]=S.[GLConfigurationId],[GLSegmentValue]=S.[GLSegmentValue],[GSTId]=S.[GSTId],[IncorporationDate]=S.[IncorporationDate],[IncorporationStateId]=S.[IncorporationStateId],[InvoiceDueDateCalculation]=S.[InvoiceDueDateCalculation],[IsAssessSalesTaxAtSKULevel]=S.[IsAssessSalesTaxAtSKULevel],[LateFeeApproach]=S.[LateFeeApproach],[LegalEntityNumber]=S.[LegalEntityNumber],[LessorWebAddress]=S.[LessorWebAddress],[Name]=S.[Name],[NonAccrualRuleTemplateId]=S.[NonAccrualRuleTemplateId],[NonUSDeferredTaxAccountNumber]=S.[NonUSDeferredTaxAccountNumber],[OrganizationID]=S.[OrganizationID],[ParentId]=S.[ParentId],[PSTQSTId]=S.[PSTQSTId],[ReAccrualRuleTemplateId]=S.[ReAccrualRuleTemplateId],[ReceiptHierarchyTemplateId]=S.[ReceiptHierarchyTemplateId],[Status]=S.[Status],[SupportsVAT]=S.[SupportsVAT],[TaxAssessmentLevel]=S.[TaxAssessmentLevel],[TaxDepBasisCurrencyId]=S.[TaxDepBasisCurrencyId],[TaxFiscalYearBeginMonthNo]=S.[TaxFiscalYearBeginMonthNo],[TaxID_CT]=S.[TaxID_CT],[TaxPayer]=S.[TaxPayer],[TaxRemittancePreference]=S.[TaxRemittancePreference],[ThresholdDays]=S.[ThresholdDays],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingStandard],[ACHFailureLimit],[ActivationDate],[BusinessCalendarId],[BusinessTypeId],[BusinessUnitId],[CostCenter],[CreatedById],[CreatedTime],[CurrencyCode],[CurrencyId],[DeactivationDate],[FiscalYearBeginMonthNo],[GLAccountNumber],[GLConfigurationId],[GLSegmentValue],[GSTId],[IncorporationDate],[IncorporationStateId],[InvoiceDueDateCalculation],[IsAssessSalesTaxAtSKULevel],[LateFeeApproach],[LegalEntityNumber],[LessorWebAddress],[Name],[NonAccrualRuleTemplateId],[NonUSDeferredTaxAccountNumber],[OrganizationID],[ParentId],[PSTQSTId],[ReAccrualRuleTemplateId],[ReceiptHierarchyTemplateId],[Status],[SupportsVAT],[TaxAssessmentLevel],[TaxDepBasisCurrencyId],[TaxFiscalYearBeginMonthNo],[TaxID_CT],[TaxPayer],[TaxRemittancePreference],[ThresholdDays])
    VALUES (S.[AccountingStandard],S.[ACHFailureLimit],S.[ActivationDate],S.[BusinessCalendarId],S.[BusinessTypeId],S.[BusinessUnitId],S.[CostCenter],S.[CreatedById],S.[CreatedTime],S.[CurrencyCode],S.[CurrencyId],S.[DeactivationDate],S.[FiscalYearBeginMonthNo],S.[GLAccountNumber],S.[GLConfigurationId],S.[GLSegmentValue],S.[GSTId],S.[IncorporationDate],S.[IncorporationStateId],S.[InvoiceDueDateCalculation],S.[IsAssessSalesTaxAtSKULevel],S.[LateFeeApproach],S.[LegalEntityNumber],S.[LessorWebAddress],S.[Name],S.[NonAccrualRuleTemplateId],S.[NonUSDeferredTaxAccountNumber],S.[OrganizationID],S.[ParentId],S.[PSTQSTId],S.[ReAccrualRuleTemplateId],S.[ReceiptHierarchyTemplateId],S.[Status],S.[SupportsVAT],S.[TaxAssessmentLevel],S.[TaxDepBasisCurrencyId],S.[TaxFiscalYearBeginMonthNo],S.[TaxID_CT],S.[TaxPayer],S.[TaxRemittancePreference],S.[ThresholdDays])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
