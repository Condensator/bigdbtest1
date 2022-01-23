SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepAmortJobExtract]
(
 @val [dbo].[TaxDepAmortJobExtract] READONLY
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
MERGE [dbo].[TaxDepAmortJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowableCredit]=S.[AllowableCredit],[AssetId]=S.[AssetId],[BlendedItemId]=S.[BlendedItemId],[BlendedItemName]=S.[BlendedItemName],[ContractCurrencyISO]=S.[ContractCurrencyISO],[ContractId]=S.[ContractId],[ContractSequenceNumber]=S.[ContractSequenceNumber],[CostCenterId]=S.[CostCenterId],[CurrentTaxAssetSetupGLTemplateId]=S.[CurrentTaxAssetSetupGLTemplateId],[CurrentTaxDepExpenseGLTemplateId]=S.[CurrentTaxDepExpenseGLTemplateId],[DepreciationBeginDate]=S.[DepreciationBeginDate],[DepreciationEndDate]=S.[DepreciationEndDate],[EntityType]=S.[EntityType],[EtcBlendedItemTaxCreditTaxBasisPercentage]=S.[EtcBlendedItemTaxCreditTaxBasisPercentage],[FiscalYearBeginMonth]=S.[FiscalYearBeginMonth],[FiscalYearEndMonth]=S.[FiscalYearEndMonth],[FXTaxBasisAmount_Amount]=S.[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency]=S.[FXTaxBasisAmount_Currency],[GLFinancialOpenPeriodFromDate]=S.[GLFinancialOpenPeriodFromDate],[InstrumentTypeId]=S.[InstrumentTypeId],[IsAssetCountryUSA]=S.[IsAssetCountryUSA],[IsComputationPending]=S.[IsComputationPending],[IsConditionalSale]=S.[IsConditionalSale],[IsGLPosted]=S.[IsGLPosted],[IsRecoverOverFixedTerm]=S.[IsRecoverOverFixedTerm],[IsStraightLineMethodUsed]=S.[IsStraightLineMethodUsed],[IsSubmitted]=S.[IsSubmitted],[IsTaxDepreciationTerminated]=S.[IsTaxDepreciationTerminated],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetId]=S.[LeaseAssetId],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[ReversalPostDate]=S.[ReversalPostDate],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[TaxAssetSetupGLTemplateId]=S.[TaxAssetSetupGLTemplateId],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[TaxDepAmortizationId]=S.[TaxDepAmortizationId],[TaxDepDisposalGLTemplateId]=S.[TaxDepDisposalGLTemplateId],[TaxDepEntityId]=S.[TaxDepEntityId],[TaxDepExpenseGLTemplateId]=S.[TaxDepExpenseGLTemplateId],[TaxDepGLReversalDate]=S.[TaxDepGLReversalDate],[TaxDepTemplateId]=S.[TaxDepTemplateId],[TaxProceedsAmount_Amount]=S.[TaxProceedsAmount_Amount],[TaxProceedsAmount_Currency]=S.[TaxProceedsAmount_Currency],[TerminationDate]=S.[TerminationDate],[TerminationFiscalYear]=S.[TerminationFiscalYear],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllowableCredit],[AssetId],[BlendedItemId],[BlendedItemName],[ContractCurrencyISO],[ContractId],[ContractSequenceNumber],[CostCenterId],[CreatedById],[CreatedTime],[CurrentTaxAssetSetupGLTemplateId],[CurrentTaxDepExpenseGLTemplateId],[DepreciationBeginDate],[DepreciationEndDate],[EntityType],[EtcBlendedItemTaxCreditTaxBasisPercentage],[FiscalYearBeginMonth],[FiscalYearEndMonth],[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency],[GLFinancialOpenPeriodFromDate],[InstrumentTypeId],[IsAssetCountryUSA],[IsComputationPending],[IsConditionalSale],[IsGLPosted],[IsRecoverOverFixedTerm],[IsStraightLineMethodUsed],[IsSubmitted],[IsTaxDepreciationTerminated],[JobStepInstanceId],[LeaseAssetId],[LegalEntityId],[LineOfBusinessId],[ReversalPostDate],[TaskChunkServiceInstanceId],[TaxAssetSetupGLTemplateId],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency],[TaxDepAmortizationId],[TaxDepDisposalGLTemplateId],[TaxDepEntityId],[TaxDepExpenseGLTemplateId],[TaxDepGLReversalDate],[TaxDepTemplateId],[TaxProceedsAmount_Amount],[TaxProceedsAmount_Currency],[TerminationDate],[TerminationFiscalYear])
    VALUES (S.[AllowableCredit],S.[AssetId],S.[BlendedItemId],S.[BlendedItemName],S.[ContractCurrencyISO],S.[ContractId],S.[ContractSequenceNumber],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrentTaxAssetSetupGLTemplateId],S.[CurrentTaxDepExpenseGLTemplateId],S.[DepreciationBeginDate],S.[DepreciationEndDate],S.[EntityType],S.[EtcBlendedItemTaxCreditTaxBasisPercentage],S.[FiscalYearBeginMonth],S.[FiscalYearEndMonth],S.[FXTaxBasisAmount_Amount],S.[FXTaxBasisAmount_Currency],S.[GLFinancialOpenPeriodFromDate],S.[InstrumentTypeId],S.[IsAssetCountryUSA],S.[IsComputationPending],S.[IsConditionalSale],S.[IsGLPosted],S.[IsRecoverOverFixedTerm],S.[IsStraightLineMethodUsed],S.[IsSubmitted],S.[IsTaxDepreciationTerminated],S.[JobStepInstanceId],S.[LeaseAssetId],S.[LegalEntityId],S.[LineOfBusinessId],S.[ReversalPostDate],S.[TaskChunkServiceInstanceId],S.[TaxAssetSetupGLTemplateId],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency],S.[TaxDepAmortizationId],S.[TaxDepDisposalGLTemplateId],S.[TaxDepEntityId],S.[TaxDepExpenseGLTemplateId],S.[TaxDepGLReversalDate],S.[TaxDepTemplateId],S.[TaxProceedsAmount_Amount],S.[TaxProceedsAmount_Currency],S.[TerminationDate],S.[TerminationFiscalYear])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
