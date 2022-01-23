SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAmendment]
(
 @val [dbo].[LeaseAmendment] READONLY
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
MERGE [dbo].[LeaseAmendments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[AccumulatedImpairmentAmount_Amount]=S.[AccumulatedImpairmentAmount_Amount],[AccumulatedImpairmentAmount_Currency]=S.[AccumulatedImpairmentAmount_Currency],[AmendmentAtInception]=S.[AmendmentAtInception],[AmendmentDate]=S.[AmendmentDate],[AmendmentReasonComment]=S.[AmendmentReasonComment],[AmendmentReasonId]=S.[AmendmentReasonId],[AmendmentType]=S.[AmendmentType],[BillToId]=S.[BillToId],[CreateCPURestructure]=S.[CreateCPURestructure],[CurrentLeaseFinanceId]=S.[CurrentLeaseFinanceId],[DealProductTypeId]=S.[DealProductTypeId],[DealTypeId]=S.[DealTypeId],[Description]=S.[Description],[FinalAcceptanceDate]=S.[FinalAcceptanceDate],[FloatRateRestructure]=S.[FloatRateRestructure],[GLTemplateId]=S.[GLTemplateId],[GSTTaxPaidtoVendor_Amount]=S.[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency]=S.[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount]=S.[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency]=S.[HSTTaxPaidtoVendor_Currency],[ImpairmentAmount_Amount]=S.[ImpairmentAmount_Amount],[ImpairmentAmount_Currency]=S.[ImpairmentAmount_Currency],[InvoiceComment]=S.[InvoiceComment],[IsLeaseLevelImpairment]=S.[IsLeaseLevelImpairment],[IsLienFilingException]=S.[IsLienFilingException],[IsLienFilingRequired]=S.[IsLienFilingRequired],[IsTDR]=S.[IsTDR],[LeaseAlias]=S.[LeaseAlias],[LeaseAmendmentStatus]=S.[LeaseAmendmentStatus],[LeasePaymentScheduleId]=S.[LeasePaymentScheduleId],[LeaseSequenceNumber]=S.[LeaseSequenceNumber],[LienExceptionComment]=S.[LienExceptionComment],[LienExceptionReason]=S.[LienExceptionReason],[Name]=S.[Name],[NetWritedowns_Amount]=S.[NetWritedowns_Amount],[NetWritedowns_Currency]=S.[NetWritedowns_Currency],[OriginalDealProductTypeId]=S.[OriginalDealProductTypeId],[OriginalLeaseFinanceId]=S.[OriginalLeaseFinanceId],[PaymentDate]=S.[PaymentDate],[PayOffGLTemplateId]=S.[PayOffGLTemplateId],[PostDate]=S.[PostDate],[PostRestructureFAS91Balance_Amount]=S.[PostRestructureFAS91Balance_Amount],[PostRestructureFAS91Balance_Currency]=S.[PostRestructureFAS91Balance_Currency],[PostRestructureLeaseNBV_Amount]=S.[PostRestructureLeaseNBV_Amount],[PostRestructureLeaseNBV_Currency]=S.[PostRestructureLeaseNBV_Currency],[PostRestructureResidualBooked_Amount]=S.[PostRestructureResidualBooked_Amount],[PostRestructureResidualBooked_Currency]=S.[PostRestructureResidualBooked_Currency],[PostRestructureUnguaranteedResidual_Amount]=S.[PostRestructureUnguaranteedResidual_Amount],[PostRestructureUnguaranteedResidual_Currency]=S.[PostRestructureUnguaranteedResidual_Currency],[PreRestructureClassificationYield]=S.[PreRestructureClassificationYield],[PreRestructureClassificationYield5A]=S.[PreRestructureClassificationYield5A],[PreRestructureClassificationYield5B]=S.[PreRestructureClassificationYield5B],[PreRestructureFAS91Balance_Amount]=S.[PreRestructureFAS91Balance_Amount],[PreRestructureFAS91Balance_Currency]=S.[PreRestructureFAS91Balance_Currency],[PreRestructureLeaseNBV_Amount]=S.[PreRestructureLeaseNBV_Amount],[PreRestructureLeaseNBV_Currency]=S.[PreRestructureLeaseNBV_Currency],[PreRestructureLessorYield]=S.[PreRestructureLessorYield],[PreRestructureLessorYieldFinanceAsset]=S.[PreRestructureLessorYieldFinanceAsset],[PreRestructureLessorYieldLeaseAsset]=S.[PreRestructureLessorYieldLeaseAsset],[PreRestructureResidualBooked_Amount]=S.[PreRestructureResidualBooked_Amount],[PreRestructureResidualBooked_Currency]=S.[PreRestructureResidualBooked_Currency],[PreRestructureUnguaranteedResidual_Amount]=S.[PreRestructureUnguaranteedResidual_Amount],[PreRestructureUnguaranteedResidual_Currency]=S.[PreRestructureUnguaranteedResidual_Currency],[QSTorPSTTaxPaidtoVendor_Amount]=S.[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency]=S.[QSTorPSTTaxPaidtoVendor_Currency],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[RemitToId]=S.[RemitToId],[SalesTaxRemittanceMethod]=S.[SalesTaxRemittanceMethod],[TaxPaidtoVendor_Amount]=S.[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency]=S.[TaxPaidtoVendor_Currency],[TDRReason]=S.[TDRReason],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[AccumulatedImpairmentAmount_Amount],[AccumulatedImpairmentAmount_Currency],[AmendmentAtInception],[AmendmentDate],[AmendmentReasonComment],[AmendmentReasonId],[AmendmentType],[BillToId],[CreateCPURestructure],[CreatedById],[CreatedTime],[CurrentLeaseFinanceId],[DealProductTypeId],[DealTypeId],[Description],[FinalAcceptanceDate],[FloatRateRestructure],[GLTemplateId],[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency],[ImpairmentAmount_Amount],[ImpairmentAmount_Currency],[InvoiceComment],[IsLeaseLevelImpairment],[IsLienFilingException],[IsLienFilingRequired],[IsTDR],[LeaseAlias],[LeaseAmendmentStatus],[LeasePaymentScheduleId],[LeaseSequenceNumber],[LienExceptionComment],[LienExceptionReason],[Name],[NetWritedowns_Amount],[NetWritedowns_Currency],[OriginalDealProductTypeId],[OriginalLeaseFinanceId],[PaymentDate],[PayOffGLTemplateId],[PostDate],[PostRestructureFAS91Balance_Amount],[PostRestructureFAS91Balance_Currency],[PostRestructureLeaseNBV_Amount],[PostRestructureLeaseNBV_Currency],[PostRestructureResidualBooked_Amount],[PostRestructureResidualBooked_Currency],[PostRestructureUnguaranteedResidual_Amount],[PostRestructureUnguaranteedResidual_Currency],[PreRestructureClassificationYield],[PreRestructureClassificationYield5A],[PreRestructureClassificationYield5B],[PreRestructureFAS91Balance_Amount],[PreRestructureFAS91Balance_Currency],[PreRestructureLeaseNBV_Amount],[PreRestructureLeaseNBV_Currency],[PreRestructureLessorYield],[PreRestructureLessorYieldFinanceAsset],[PreRestructureLessorYieldLeaseAsset],[PreRestructureResidualBooked_Amount],[PreRestructureResidualBooked_Currency],[PreRestructureUnguaranteedResidual_Amount],[PreRestructureUnguaranteedResidual_Currency],[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency],[ReceivableAmendmentType],[RemitToId],[SalesTaxRemittanceMethod],[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency],[TDRReason])
    VALUES (S.[AccountingDate],S.[AccumulatedImpairmentAmount_Amount],S.[AccumulatedImpairmentAmount_Currency],S.[AmendmentAtInception],S.[AmendmentDate],S.[AmendmentReasonComment],S.[AmendmentReasonId],S.[AmendmentType],S.[BillToId],S.[CreateCPURestructure],S.[CreatedById],S.[CreatedTime],S.[CurrentLeaseFinanceId],S.[DealProductTypeId],S.[DealTypeId],S.[Description],S.[FinalAcceptanceDate],S.[FloatRateRestructure],S.[GLTemplateId],S.[GSTTaxPaidtoVendor_Amount],S.[GSTTaxPaidtoVendor_Currency],S.[HSTTaxPaidtoVendor_Amount],S.[HSTTaxPaidtoVendor_Currency],S.[ImpairmentAmount_Amount],S.[ImpairmentAmount_Currency],S.[InvoiceComment],S.[IsLeaseLevelImpairment],S.[IsLienFilingException],S.[IsLienFilingRequired],S.[IsTDR],S.[LeaseAlias],S.[LeaseAmendmentStatus],S.[LeasePaymentScheduleId],S.[LeaseSequenceNumber],S.[LienExceptionComment],S.[LienExceptionReason],S.[Name],S.[NetWritedowns_Amount],S.[NetWritedowns_Currency],S.[OriginalDealProductTypeId],S.[OriginalLeaseFinanceId],S.[PaymentDate],S.[PayOffGLTemplateId],S.[PostDate],S.[PostRestructureFAS91Balance_Amount],S.[PostRestructureFAS91Balance_Currency],S.[PostRestructureLeaseNBV_Amount],S.[PostRestructureLeaseNBV_Currency],S.[PostRestructureResidualBooked_Amount],S.[PostRestructureResidualBooked_Currency],S.[PostRestructureUnguaranteedResidual_Amount],S.[PostRestructureUnguaranteedResidual_Currency],S.[PreRestructureClassificationYield],S.[PreRestructureClassificationYield5A],S.[PreRestructureClassificationYield5B],S.[PreRestructureFAS91Balance_Amount],S.[PreRestructureFAS91Balance_Currency],S.[PreRestructureLeaseNBV_Amount],S.[PreRestructureLeaseNBV_Currency],S.[PreRestructureLessorYield],S.[PreRestructureLessorYieldFinanceAsset],S.[PreRestructureLessorYieldLeaseAsset],S.[PreRestructureResidualBooked_Amount],S.[PreRestructureResidualBooked_Currency],S.[PreRestructureUnguaranteedResidual_Amount],S.[PreRestructureUnguaranteedResidual_Currency],S.[QSTorPSTTaxPaidtoVendor_Amount],S.[QSTorPSTTaxPaidtoVendor_Currency],S.[ReceivableAmendmentType],S.[RemitToId],S.[SalesTaxRemittanceMethod],S.[TaxPaidtoVendor_Amount],S.[TaxPaidtoVendor_Currency],S.[TDRReason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO