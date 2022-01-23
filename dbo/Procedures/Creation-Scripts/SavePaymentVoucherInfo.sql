SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaymentVoucherInfo]
(
 @val [dbo].[PaymentVoucherInfo] READONLY
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
MERGE [dbo].[PaymentVoucherInfoes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [APGLTemplateId]=S.[APGLTemplateId],[BillToId]=S.[BillToId],[BranchId]=S.[BranchId],[ClearingOption]=S.[ClearingOption],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsManual]=S.[IsManual],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[MailingInstruction]=S.[MailingInstruction],[Memo]=S.[Memo],[PayeeName]=S.[PayeeName],[PayFromAccountId]=S.[PayFromAccountId],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentVoucherStatus]=S.[PaymentVoucherStatus],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableRemitToId]=S.[ReceivableRemitToId],[RemittanceType]=S.[RemittanceType],[RemitToId]=S.[RemitToId],[RequestedDate]=S.[RequestedDate],[SundryId]=S.[SundryId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Urgency]=S.[Urgency],[WithholdingTaxAmount_Amount]=S.[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency]=S.[WithholdingTaxAmount_Currency],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AccountsPayableId],[APGLTemplateId],[BillToId],[BranchId],[ClearingOption],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[InstrumentTypeId],[IsManual],[LegalEntityId],[LineofBusinessId],[LocationId],[MailingInstruction],[Memo],[PayeeName],[PayFromAccountId],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentVoucherStatus],[ReceivableCodeId],[ReceivableDueDate],[ReceivableRemitToId],[RemittanceType],[RemitToId],[RequestedDate],[SundryId],[Urgency],[WithholdingTaxAmount_Amount],[WithholdingTaxAmount_Currency],[WithholdingTaxRate])
    VALUES (S.[AccountsPayableId],S.[APGLTemplateId],S.[BillToId],S.[BranchId],S.[ClearingOption],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[InstrumentTypeId],S.[IsManual],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[MailingInstruction],S.[Memo],S.[PayeeName],S.[PayFromAccountId],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentVoucherStatus],S.[ReceivableCodeId],S.[ReceivableDueDate],S.[ReceivableRemitToId],S.[RemittanceType],S.[RemitToId],S.[RequestedDate],S.[SundryId],S.[Urgency],S.[WithholdingTaxAmount_Amount],S.[WithholdingTaxAmount_Currency],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
