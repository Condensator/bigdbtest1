SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePPTInvoice]
(
 @val [dbo].[PPTInvoice] READONLY
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
MERGE [dbo].[PPTInvoices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountNumber]=S.[AccountNumber],[ApprovalStatus]=S.[ApprovalStatus],[AVNoticeId]=S.[AVNoticeId],[BatchNumber]=S.[BatchNumber],[BillableAmount_Amount]=S.[BillableAmount_Amount],[BillableAmount_Currency]=S.[BillableAmount_Currency],[Comment]=S.[Comment],[CostCenterId]=S.[CostCenterId],[DiscountDueDate]=S.[DiscountDueDate],[DueDate]=S.[DueDate],[FollowUpDate]=S.[FollowUpDate],[InvoiceDate]=S.[InvoiceDate],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[LienDate]=S.[LienDate],[LineofBusinessId]=S.[LineofBusinessId],[Location]=S.[Location],[NonBillableAmount_Amount]=S.[NonBillableAmount_Amount],[NonBillableAmount_Currency]=S.[NonBillableAmount_Currency],[ParcelNumber]=S.[ParcelNumber],[PayableCodeDescription]=S.[PayableCodeDescription],[PayableCodeId]=S.[PayableCodeId],[PayableId]=S.[PayableId],[PPTAdministartionFees_Amount]=S.[PPTAdministartionFees_Amount],[PPTAdministartionFees_Currency]=S.[PPTAdministartionFees_Currency],[PPTEarlyPaymentDiscount_Amount]=S.[PPTEarlyPaymentDiscount_Amount],[PPTEarlyPaymentDiscount_Currency]=S.[PPTEarlyPaymentDiscount_Currency],[PPTInterest_Amount]=S.[PPTInterest_Amount],[PPTInterest_Currency]=S.[PPTInterest_Currency],[PPTInvoiceNumber]=S.[PPTInvoiceNumber],[PPTLienFees_Amount]=S.[PPTLienFees_Amount],[PPTLienFees_Currency]=S.[PPTLienFees_Currency],[PPTPenalty_Amount]=S.[PPTPenalty_Amount],[PPTPenalty_Currency]=S.[PPTPenalty_Currency],[PPTTaxBase_Amount]=S.[PPTTaxBase_Amount],[PPTTaxBase_Currency]=S.[PPTTaxBase_Currency],[PPTUnbilledWriteOff_Amount]=S.[PPTUnbilledWriteOff_Amount],[PPTUnbilledWriteOff_Currency]=S.[PPTUnbilledWriteOff_Currency],[PPTVendorId]=S.[PPTVendorId],[ReceivedDate]=S.[ReceivedDate],[RenderedValue_Amount]=S.[RenderedValue_Amount],[RenderedValue_Currency]=S.[RenderedValue_Currency],[RenderedValueDifference]=S.[RenderedValueDifference],[StateId]=S.[StateId],[TaxBillType]=S.[TaxBillType],[TaxEntity]=S.[TaxEntity],[TaxYear]=S.[TaxYear],[TotalAssessed_Amount]=S.[TotalAssessed_Amount],[TotalAssessed_Currency]=S.[TotalAssessed_Currency],[TotalPPTPayableAmount_Amount]=S.[TotalPPTPayableAmount_Amount],[TotalPPTPayableAmount_Currency]=S.[TotalPPTPayableAmount_Currency],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AccountNumber],[ApprovalStatus],[AVNoticeId],[BatchNumber],[BillableAmount_Amount],[BillableAmount_Currency],[Comment],[CostCenterId],[CreatedById],[CreatedTime],[DiscountDueDate],[DueDate],[FollowUpDate],[InvoiceDate],[IsActive],[LegalEntityId],[LienDate],[LineofBusinessId],[Location],[NonBillableAmount_Amount],[NonBillableAmount_Currency],[ParcelNumber],[PayableCodeDescription],[PayableCodeId],[PayableId],[PPTAdministartionFees_Amount],[PPTAdministartionFees_Currency],[PPTEarlyPaymentDiscount_Amount],[PPTEarlyPaymentDiscount_Currency],[PPTInterest_Amount],[PPTInterest_Currency],[PPTInvoiceNumber],[PPTLienFees_Amount],[PPTLienFees_Currency],[PPTPenalty_Amount],[PPTPenalty_Currency],[PPTTaxBase_Amount],[PPTTaxBase_Currency],[PPTUnbilledWriteOff_Amount],[PPTUnbilledWriteOff_Currency],[PPTVendorId],[ReceivedDate],[RenderedValue_Amount],[RenderedValue_Currency],[RenderedValueDifference],[StateId],[TaxBillType],[TaxEntity],[TaxYear],[TotalAssessed_Amount],[TotalAssessed_Currency],[TotalPPTPayableAmount_Amount],[TotalPPTPayableAmount_Currency],[Type],[WithholdingTaxRate])
    VALUES (S.[AccountNumber],S.[ApprovalStatus],S.[AVNoticeId],S.[BatchNumber],S.[BillableAmount_Amount],S.[BillableAmount_Currency],S.[Comment],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[DiscountDueDate],S.[DueDate],S.[FollowUpDate],S.[InvoiceDate],S.[IsActive],S.[LegalEntityId],S.[LienDate],S.[LineofBusinessId],S.[Location],S.[NonBillableAmount_Amount],S.[NonBillableAmount_Currency],S.[ParcelNumber],S.[PayableCodeDescription],S.[PayableCodeId],S.[PayableId],S.[PPTAdministartionFees_Amount],S.[PPTAdministartionFees_Currency],S.[PPTEarlyPaymentDiscount_Amount],S.[PPTEarlyPaymentDiscount_Currency],S.[PPTInterest_Amount],S.[PPTInterest_Currency],S.[PPTInvoiceNumber],S.[PPTLienFees_Amount],S.[PPTLienFees_Currency],S.[PPTPenalty_Amount],S.[PPTPenalty_Currency],S.[PPTTaxBase_Amount],S.[PPTTaxBase_Currency],S.[PPTUnbilledWriteOff_Amount],S.[PPTUnbilledWriteOff_Currency],S.[PPTVendorId],S.[ReceivedDate],S.[RenderedValue_Amount],S.[RenderedValue_Currency],S.[RenderedValueDifference],S.[StateId],S.[TaxBillType],S.[TaxEntity],S.[TaxYear],S.[TotalAssessed_Amount],S.[TotalAssessed_Currency],S.[TotalPPTPayableAmount_Amount],S.[TotalPPTPayableAmount_Currency],S.[Type],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
