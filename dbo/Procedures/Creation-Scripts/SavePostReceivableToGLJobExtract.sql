SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePostReceivableToGLJobExtract]
(
 @val [dbo].[PostReceivableToGLJobExtract] READONLY
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
MERGE [dbo].[PostReceivableToGLJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[AcquisitionId]=S.[AcquisitionId],[APGLTemplateId]=S.[APGLTemplateId],[BlendedItemId]=S.[BlendedItemId],[BookingGLTemplateId]=S.[BookingGLTemplateId],[BranchId]=S.[BranchId],[CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CustomerId]=S.[CustomerId],[DealProductTypeId]=S.[DealProductTypeId],[DiscountingId]=S.[DiscountingId],[DueDate]=S.[DueDate],[EntityType]=S.[EntityType],[ErrorMessage]=S.[ErrorMessage],[FinancingPrepaidAmount]=S.[FinancingPrepaidAmount],[FinancingTotalAmount]=S.[FinancingTotalAmount],[FunderId]=S.[FunderId],[GLTemplateId]=S.[GLTemplateId],[GLTransactionType]=S.[GLTransactionType],[IncomeType]=S.[IncomeType],[InstrumentTypeId]=S.[InstrumentTypeId],[IsCashBased]=S.[IsCashBased],[IsChargedOffContract]=S.[IsChargedOffContract],[IsContractSyndicated]=S.[IsContractSyndicated],[IsDSL]=S.[IsDSL],[IsIntercompany]=S.[IsIntercompany],[IsReceivableTaxValid]=S.[IsReceivableTaxValid],[IsReceivableValid]=S.[IsReceivableValid],[IsSubmitted]=S.[IsSubmitted],[IsSundryBlendedItemFAS91]=S.[IsSundryBlendedItemFAS91],[IsTiedToDiscounting]=S.[IsTiedToDiscounting],[IsVendorOwned]=S.[IsVendorOwned],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseInterimInterestIncomeGLTemplateId]=S.[LeaseInterimInterestIncomeGLTemplateId],[LeaseInterimRentIncomeGLTemplateId]=S.[LeaseInterimRentIncomeGLTemplateId],[LegalEntityId]=S.[LegalEntityId],[LineOfBusinessId]=S.[LineOfBusinessId],[LoanIncomeRecognitionGLTemplateId]=S.[LoanIncomeRecognitionGLTemplateId],[LoanInterimIncomeRecognitionGLTemplateId]=S.[LoanInterimIncomeRecognitionGLTemplateId],[PostDate]=S.[PostDate],[PrepaidAmount]=S.[PrepaidAmount],[ProcessThroughDate]=S.[ProcessThroughDate],[ReceivableCode]=S.[ReceivableCode],[ReceivableForTransferId]=S.[ReceivableForTransferId],[ReceivableForTransferType]=S.[ReceivableForTransferType],[ReceivableGlTransactionType]=S.[ReceivableGlTransactionType],[ReceivableId]=S.[ReceivableId],[ReceivableIsCollected]=S.[ReceivableIsCollected],[ReceivableTaxId]=S.[ReceivableTaxId],[SecurityDepositId]=S.[SecurityDepositId],[StartDate]=S.[StartDate],[SundryBlendedItemBookingGlTemplateId]=S.[SundryBlendedItemBookingGlTemplateId],[SyndicationGLTemplateId]=S.[SyndicationGLTemplateId],[SyndicationGLTransactionType]=S.[SyndicationGLTransactionType],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[TaxBalanceAmount]=S.[TaxBalanceAmount],[TaxCurrencyCode]=S.[TaxCurrencyCode],[TaxGlTemplateId]=S.[TaxGlTemplateId],[TaxTotalAmount]=S.[TaxTotalAmount],[TotalAmount]=S.[TotalAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[AcquisitionId],[APGLTemplateId],[BlendedItemId],[BookingGLTemplateId],[BranchId],[CommencementDate],[ContractId],[ContractType],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CustomerId],[DealProductTypeId],[DiscountingId],[DueDate],[EntityType],[ErrorMessage],[FinancingPrepaidAmount],[FinancingTotalAmount],[FunderId],[GLTemplateId],[GLTransactionType],[IncomeType],[InstrumentTypeId],[IsCashBased],[IsChargedOffContract],[IsContractSyndicated],[IsDSL],[IsIntercompany],[IsReceivableTaxValid],[IsReceivableValid],[IsSubmitted],[IsSundryBlendedItemFAS91],[IsTiedToDiscounting],[IsVendorOwned],[JobStepInstanceId],[LeaseInterimInterestIncomeGLTemplateId],[LeaseInterimRentIncomeGLTemplateId],[LegalEntityId],[LineOfBusinessId],[LoanIncomeRecognitionGLTemplateId],[LoanInterimIncomeRecognitionGLTemplateId],[PostDate],[PrepaidAmount],[ProcessThroughDate],[ReceivableCode],[ReceivableForTransferId],[ReceivableForTransferType],[ReceivableGlTransactionType],[ReceivableId],[ReceivableIsCollected],[ReceivableTaxId],[SecurityDepositId],[StartDate],[SundryBlendedItemBookingGlTemplateId],[SyndicationGLTemplateId],[SyndicationGLTransactionType],[TaskChunkServiceInstanceId],[TaxBalanceAmount],[TaxCurrencyCode],[TaxGlTemplateId],[TaxTotalAmount],[TotalAmount])
    VALUES (S.[AccountingTreatment],S.[AcquisitionId],S.[APGLTemplateId],S.[BlendedItemId],S.[BookingGLTemplateId],S.[BranchId],S.[CommencementDate],S.[ContractId],S.[ContractType],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CustomerId],S.[DealProductTypeId],S.[DiscountingId],S.[DueDate],S.[EntityType],S.[ErrorMessage],S.[FinancingPrepaidAmount],S.[FinancingTotalAmount],S.[FunderId],S.[GLTemplateId],S.[GLTransactionType],S.[IncomeType],S.[InstrumentTypeId],S.[IsCashBased],S.[IsChargedOffContract],S.[IsContractSyndicated],S.[IsDSL],S.[IsIntercompany],S.[IsReceivableTaxValid],S.[IsReceivableValid],S.[IsSubmitted],S.[IsSundryBlendedItemFAS91],S.[IsTiedToDiscounting],S.[IsVendorOwned],S.[JobStepInstanceId],S.[LeaseInterimInterestIncomeGLTemplateId],S.[LeaseInterimRentIncomeGLTemplateId],S.[LegalEntityId],S.[LineOfBusinessId],S.[LoanIncomeRecognitionGLTemplateId],S.[LoanInterimIncomeRecognitionGLTemplateId],S.[PostDate],S.[PrepaidAmount],S.[ProcessThroughDate],S.[ReceivableCode],S.[ReceivableForTransferId],S.[ReceivableForTransferType],S.[ReceivableGlTransactionType],S.[ReceivableId],S.[ReceivableIsCollected],S.[ReceivableTaxId],S.[SecurityDepositId],S.[StartDate],S.[SundryBlendedItemBookingGlTemplateId],S.[SyndicationGLTemplateId],S.[SyndicationGLTransactionType],S.[TaskChunkServiceInstanceId],S.[TaxBalanceAmount],S.[TaxCurrencyCode],S.[TaxGlTemplateId],S.[TaxTotalAmount],S.[TotalAmount])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
