SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableForTransfer]
(
 @val [dbo].[ReceivableForTransfer] READONLY
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
MERGE [dbo].[ReceivableForTransfers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[ActualProceeds_Amount]=S.[ActualProceeds_Amount],[ActualProceeds_Currency]=S.[ActualProceeds_Currency],[Alias]=S.[Alias],[ApprovalStatus]=S.[ApprovalStatus],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[DayCountConvention]=S.[DayCountConvention],[DiscountRate]=S.[DiscountRate],[EffectiveDate]=S.[EffectiveDate],[FinancingSoldNBV_Amount]=S.[FinancingSoldNBV_Amount],[FinancingSoldNBV_Currency]=S.[FinancingSoldNBV_Currency],[FinancingTotalNBV_Amount]=S.[FinancingTotalNBV_Amount],[FinancingTotalNBV_Currency]=S.[FinancingTotalNBV_Currency],[FundingDate]=S.[FundingDate],[IsBlendedItemParametersChanged]=S.[IsBlendedItemParametersChanged],[IsCalculatePercentage]=S.[IsCalculatePercentage],[IsCalculateRate]=S.[IsCalculateRate],[IsFromContract]=S.[IsFromContract],[IsPricingParametersChanged]=S.[IsPricingParametersChanged],[IsPricingPerformed]=S.[IsPricingPerformed],[LeaseFinanceId]=S.[LeaseFinanceId],[LeasePaymentId]=S.[LeasePaymentId],[LegalEntityId]=S.[LegalEntityId],[LoanFinanceId]=S.[LoanFinanceId],[LoanPaymentId]=S.[LoanPaymentId],[Name]=S.[Name],[Number]=S.[Number],[OldProceedsReceivableCodeId]=S.[OldProceedsReceivableCodeId],[PostDate]=S.[PostDate],[ProceedsReceivableCodeId]=S.[ProceedsReceivableCodeId],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[ReceivableForTransferType]=S.[ReceivableForTransferType],[RemitToId]=S.[RemitToId],[RentalProceedsPayableCodeId]=S.[RentalProceedsPayableCodeId],[RentalProceedsWithholdingTaxRate]=S.[RentalProceedsWithholdingTaxRate],[RetainedPercentage]=S.[RetainedPercentage],[ScrapeReceivableCodeId]=S.[ScrapeReceivableCodeId],[SecurityDeposit_Amount]=S.[SecurityDeposit_Amount],[SecurityDeposit_Currency]=S.[SecurityDeposit_Currency],[SoldInterestAccrued_Amount]=S.[SoldInterestAccrued_Amount],[SoldInterestAccrued_Currency]=S.[SoldInterestAccrued_Currency],[SoldNBV_Amount]=S.[SoldNBV_Amount],[SoldNBV_Currency]=S.[SoldNBV_Currency],[SyndicationGLJournalId]=S.[SyndicationGLJournalId],[SyndicationGLTemplateId]=S.[SyndicationGLTemplateId],[TaxDepDisposalTemplateId]=S.[TaxDepDisposalTemplateId],[TotalNBV_Amount]=S.[TotalNBV_Amount],[TotalNBV_Currency]=S.[TotalNBV_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontSyndicationFeeCodeId]=S.[UpfrontSyndicationFeeCodeId]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[ActualProceeds_Amount],[ActualProceeds_Currency],[Alias],[ApprovalStatus],[Comment],[ContractId],[ContractType],[CreatedById],[CreatedTime],[DayCountConvention],[DiscountRate],[EffectiveDate],[FinancingSoldNBV_Amount],[FinancingSoldNBV_Currency],[FinancingTotalNBV_Amount],[FinancingTotalNBV_Currency],[FundingDate],[IsBlendedItemParametersChanged],[IsCalculatePercentage],[IsCalculateRate],[IsFromContract],[IsPricingParametersChanged],[IsPricingPerformed],[LeaseFinanceId],[LeasePaymentId],[LegalEntityId],[LoanFinanceId],[LoanPaymentId],[Name],[Number],[OldProceedsReceivableCodeId],[PostDate],[ProceedsReceivableCodeId],[ReceiptGLTemplateId],[ReceivableForTransferType],[RemitToId],[RentalProceedsPayableCodeId],[RentalProceedsWithholdingTaxRate],[RetainedPercentage],[ScrapeReceivableCodeId],[SecurityDeposit_Amount],[SecurityDeposit_Currency],[SoldInterestAccrued_Amount],[SoldInterestAccrued_Currency],[SoldNBV_Amount],[SoldNBV_Currency],[SyndicationGLJournalId],[SyndicationGLTemplateId],[TaxDepDisposalTemplateId],[TotalNBV_Amount],[TotalNBV_Currency],[UpfrontSyndicationFeeCodeId])
    VALUES (S.[AccountingDate],S.[ActualProceeds_Amount],S.[ActualProceeds_Currency],S.[Alias],S.[ApprovalStatus],S.[Comment],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[DayCountConvention],S.[DiscountRate],S.[EffectiveDate],S.[FinancingSoldNBV_Amount],S.[FinancingSoldNBV_Currency],S.[FinancingTotalNBV_Amount],S.[FinancingTotalNBV_Currency],S.[FundingDate],S.[IsBlendedItemParametersChanged],S.[IsCalculatePercentage],S.[IsCalculateRate],S.[IsFromContract],S.[IsPricingParametersChanged],S.[IsPricingPerformed],S.[LeaseFinanceId],S.[LeasePaymentId],S.[LegalEntityId],S.[LoanFinanceId],S.[LoanPaymentId],S.[Name],S.[Number],S.[OldProceedsReceivableCodeId],S.[PostDate],S.[ProceedsReceivableCodeId],S.[ReceiptGLTemplateId],S.[ReceivableForTransferType],S.[RemitToId],S.[RentalProceedsPayableCodeId],S.[RentalProceedsWithholdingTaxRate],S.[RetainedPercentage],S.[ScrapeReceivableCodeId],S.[SecurityDeposit_Amount],S.[SecurityDeposit_Currency],S.[SoldInterestAccrued_Amount],S.[SoldInterestAccrued_Currency],S.[SoldNBV_Amount],S.[SoldNBV_Currency],S.[SyndicationGLJournalId],S.[SyndicationGLTemplateId],S.[TaxDepDisposalTemplateId],S.[TotalNBV_Amount],S.[TotalNBV_Currency],S.[UpfrontSyndicationFeeCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
