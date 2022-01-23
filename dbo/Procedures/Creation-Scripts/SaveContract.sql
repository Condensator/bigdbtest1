SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContract]
(
 @val [dbo].[Contract] READONLY
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
MERGE [dbo].[Contracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingStandard]=S.[AccountingStandard],[Alias]=S.[Alias],[BackgroundProcessingPending]=S.[BackgroundProcessingPending],[BillToId]=S.[BillToId],[ChargeOffStatus]=S.[ChargeOffStatus],[ContractType]=S.[ContractType],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CreditApprovedStructureId]=S.[CreditApprovedStructureId],[CurrencyId]=S.[CurrencyId],[DealProductTypeId]=S.[DealProductTypeId],[DealTypeId]=S.[DealTypeId],[DecisionComments]=S.[DecisionComments],[DiscountForLoanStatus]=S.[DiscountForLoanStatus],[DiscountingSharedPercentage]=S.[DiscountingSharedPercentage],[DocumentMethod]=S.[DocumentMethod],[DoubtfulCollectability]=S.[DoubtfulCollectability],[ExternalReferenceNumber]=S.[ExternalReferenceNumber],[FinalAcceptanceDate]=S.[FinalAcceptanceDate],[FirstRightOfRefusal]=S.[FirstRightOfRefusal],[FollowOldDueDayMethod]=S.[FollowOldDueDayMethod],[GSTTaxPaidtoVendor_Amount]=S.[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency]=S.[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount]=S.[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency]=S.[HSTTaxPaidtoVendor_Currency],[InterimLoanAndSecurityAgreementDate]=S.[InterimLoanAndSecurityAgreementDate],[InvoiceComment]=S.[InvoiceComment],[IsAssignToRecovery]=S.[IsAssignToRecovery],[IsConfidential]=S.[IsConfidential],[IsLienFilingException]=S.[IsLienFilingException],[IsLienFilingRequired]=S.[IsLienFilingRequired],[IsNonAccrual]=S.[IsNonAccrual],[IsNonAccrualExempt]=S.[IsNonAccrualExempt],[IsOnHold]=S.[IsOnHold],[IsPostScratchIndicator]=S.[IsPostScratchIndicator],[IsReportableDelinquency]=S.[IsReportableDelinquency],[IsSyndictaionGeneratePayable]=S.[IsSyndictaionGeneratePayable],[LanguageId]=S.[LanguageId],[LastPaymentAmount_Amount]=S.[LastPaymentAmount_Amount],[LastPaymentAmount_Currency]=S.[LastPaymentAmount_Currency],[LastPaymentDate]=S.[LastPaymentDate],[LienExceptionComment]=S.[LienExceptionComment],[LienExceptionReason]=S.[LienExceptionReason],[LineofBusinessId]=S.[LineofBusinessId],[NonAccrualDate]=S.[NonAccrualDate],[OpportunityNumber]=S.[OpportunityNumber],[OriginalBookingDate]=S.[OriginalBookingDate],[PreviousScheduleNumber]=S.[PreviousScheduleNumber],[ProductAndServiceTypeConfigId]=S.[ProductAndServiceTypeConfigId],[ProgramIndicatorConfigId]=S.[ProgramIndicatorConfigId],[QSTorPSTTaxPaidtoVendor_Amount]=S.[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency]=S.[QSTorPSTTaxPaidtoVendor_Currency],[ReceiptHierarchyTemplateId]=S.[ReceiptHierarchyTemplateId],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[ReferenceType]=S.[ReferenceType],[RemitToId]=S.[RemitToId],[ReportStatus]=S.[ReportStatus],[SalesTaxRemittanceMethod]=S.[SalesTaxRemittanceMethod],[SequenceNumber]=S.[SequenceNumber],[ServicingRole]=S.[ServicingRole],[Status]=S.[Status],[SyndicationType]=S.[SyndicationType],[TaxAssessmentLevel]=S.[TaxAssessmentLevel],[TaxPaidtoVendor_Amount]=S.[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency]=S.[TaxPaidtoVendor_Currency],[u_ConversionSource]=S.[u_ConversionSource],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VehicleLeaseType]=S.[VehicleLeaseType]
WHEN NOT MATCHED THEN
	INSERT ([AccountingStandard],[Alias],[BackgroundProcessingPending],[BillToId],[ChargeOffStatus],[ContractType],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CreditApprovedStructureId],[CurrencyId],[DealProductTypeId],[DealTypeId],[DecisionComments],[DiscountForLoanStatus],[DiscountingSharedPercentage],[DocumentMethod],[DoubtfulCollectability],[ExternalReferenceNumber],[FinalAcceptanceDate],[FirstRightOfRefusal],[FollowOldDueDayMethod],[GSTTaxPaidtoVendor_Amount],[GSTTaxPaidtoVendor_Currency],[HSTTaxPaidtoVendor_Amount],[HSTTaxPaidtoVendor_Currency],[InterimLoanAndSecurityAgreementDate],[InvoiceComment],[IsAssignToRecovery],[IsConfidential],[IsLienFilingException],[IsLienFilingRequired],[IsNonAccrual],[IsNonAccrualExempt],[IsOnHold],[IsPostScratchIndicator],[IsReportableDelinquency],[IsSyndictaionGeneratePayable],[LanguageId],[LastPaymentAmount_Amount],[LastPaymentAmount_Currency],[LastPaymentDate],[LienExceptionComment],[LienExceptionReason],[LineofBusinessId],[NonAccrualDate],[OpportunityNumber],[OriginalBookingDate],[PreviousScheduleNumber],[ProductAndServiceTypeConfigId],[ProgramIndicatorConfigId],[QSTorPSTTaxPaidtoVendor_Amount],[QSTorPSTTaxPaidtoVendor_Currency],[ReceiptHierarchyTemplateId],[ReceivableAmendmentType],[ReferenceType],[RemitToId],[ReportStatus],[SalesTaxRemittanceMethod],[SequenceNumber],[ServicingRole],[Status],[SyndicationType],[TaxAssessmentLevel],[TaxPaidtoVendor_Amount],[TaxPaidtoVendor_Currency],[u_ConversionSource],[VehicleLeaseType])
    VALUES (S.[AccountingStandard],S.[Alias],S.[BackgroundProcessingPending],S.[BillToId],S.[ChargeOffStatus],S.[ContractType],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CreditApprovedStructureId],S.[CurrencyId],S.[DealProductTypeId],S.[DealTypeId],S.[DecisionComments],S.[DiscountForLoanStatus],S.[DiscountingSharedPercentage],S.[DocumentMethod],S.[DoubtfulCollectability],S.[ExternalReferenceNumber],S.[FinalAcceptanceDate],S.[FirstRightOfRefusal],S.[FollowOldDueDayMethod],S.[GSTTaxPaidtoVendor_Amount],S.[GSTTaxPaidtoVendor_Currency],S.[HSTTaxPaidtoVendor_Amount],S.[HSTTaxPaidtoVendor_Currency],S.[InterimLoanAndSecurityAgreementDate],S.[InvoiceComment],S.[IsAssignToRecovery],S.[IsConfidential],S.[IsLienFilingException],S.[IsLienFilingRequired],S.[IsNonAccrual],S.[IsNonAccrualExempt],S.[IsOnHold],S.[IsPostScratchIndicator],S.[IsReportableDelinquency],S.[IsSyndictaionGeneratePayable],S.[LanguageId],S.[LastPaymentAmount_Amount],S.[LastPaymentAmount_Currency],S.[LastPaymentDate],S.[LienExceptionComment],S.[LienExceptionReason],S.[LineofBusinessId],S.[NonAccrualDate],S.[OpportunityNumber],S.[OriginalBookingDate],S.[PreviousScheduleNumber],S.[ProductAndServiceTypeConfigId],S.[ProgramIndicatorConfigId],S.[QSTorPSTTaxPaidtoVendor_Amount],S.[QSTorPSTTaxPaidtoVendor_Currency],S.[ReceiptHierarchyTemplateId],S.[ReceivableAmendmentType],S.[ReferenceType],S.[RemitToId],S.[ReportStatus],S.[SalesTaxRemittanceMethod],S.[SequenceNumber],S.[ServicingRole],S.[Status],S.[SyndicationType],S.[TaxAssessmentLevel],S.[TaxPaidtoVendor_Amount],S.[TaxPaidtoVendor_Currency],S.[u_ConversionSource],S.[VehicleLeaseType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
