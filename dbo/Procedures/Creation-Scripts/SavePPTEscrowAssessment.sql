SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePPTEscrowAssessment]
(
 @val [dbo].[PPTEscrowAssessment] READONLY
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
MERGE [dbo].[PPTEscrowAssessments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[DisposistionAmount_Amount]=S.[DisposistionAmount_Amount],[DisposistionAmount_Currency]=S.[DisposistionAmount_Currency],[EscrowDisposistion]=S.[EscrowDisposistion],[EscrowProcessAmount_Amount]=S.[EscrowProcessAmount_Amount],[EscrowProcessAmount_Currency]=S.[EscrowProcessAmount_Currency],[GlJournalId]=S.[GlJournalId],[PayableCodeId]=S.[PayableCodeId],[PayableDueDate]=S.[PayableDueDate],[PayableRemitToId]=S.[PayableRemitToId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[ReceiptNonCashGLTemplateId]=S.[ReceiptNonCashGLTemplateId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableRemitToId]=S.[ReceivableRemitToId],[Status]=S.[Status],[SundryId]=S.[SundryId],[TotalEscrowAmount_Amount]=S.[TotalEscrowAmount_Amount],[TotalEscrowAmount_Currency]=S.[TotalEscrowAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[CustomerId],[DisposistionAmount_Amount],[DisposistionAmount_Currency],[EscrowDisposistion],[EscrowProcessAmount_Amount],[EscrowProcessAmount_Currency],[GlJournalId],[PayableCodeId],[PayableDueDate],[PayableRemitToId],[PayableWithholdingTaxRate],[PostDate],[ReceiptId],[ReceiptNonCashGLTemplateId],[ReceivableCodeId],[ReceivableDueDate],[ReceivableRemitToId],[Status],[SundryId],[TotalEscrowAmount_Amount],[TotalEscrowAmount_Currency],[VendorId])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DisposistionAmount_Amount],S.[DisposistionAmount_Currency],S.[EscrowDisposistion],S.[EscrowProcessAmount_Amount],S.[EscrowProcessAmount_Currency],S.[GlJournalId],S.[PayableCodeId],S.[PayableDueDate],S.[PayableRemitToId],S.[PayableWithholdingTaxRate],S.[PostDate],S.[ReceiptId],S.[ReceiptNonCashGLTemplateId],S.[ReceivableCodeId],S.[ReceivableDueDate],S.[ReceivableRemitToId],S.[Status],S.[SundryId],S.[TotalEscrowAmount_Amount],S.[TotalEscrowAmount_Currency],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
