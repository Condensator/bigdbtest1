SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDisbursementRequest]
(
 @val [dbo].[DisbursementRequest] READONLY
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
MERGE [dbo].[DisbursementRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [APGLTemplateId]=S.[APGLTemplateId],[ApplyByPayable]=S.[ApplyByPayable],[BillToId]=S.[BillToId],[BranchId]=S.[BranchId],[ClearingOption]=S.[ClearingOption],[Comment]=S.[Comment],[ContractCurrencyId]=S.[ContractCurrencyId],[ContractSequenceNumber]=S.[ContractSequenceNumber],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[ImportInvoice]=S.[ImportInvoice],[InstrumentTypeId]=S.[InstrumentTypeId],[IsFromPI]=S.[IsFromPI],[IsScheduledFunding]=S.[IsScheduledFunding],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[LocationId]=S.[LocationId],[OriginationType]=S.[OriginationType],[PayeeId]=S.[PayeeId],[PaymentDate]=S.[PaymentDate],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDueDate]=S.[ReceivableDueDate],[RejectionReasonId]=S.[RejectionReasonId],[RemitToId]=S.[RemitToId],[Status]=S.[Status],[SundryId]=S.[SundryId],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([APGLTemplateId],[ApplyByPayable],[BillToId],[BranchId],[ClearingOption],[Comment],[ContractCurrencyId],[ContractSequenceNumber],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[ImportInvoice],[InstrumentTypeId],[IsFromPI],[IsScheduledFunding],[LegalEntityId],[LineofBusinessId],[LocationId],[OriginationType],[PayeeId],[PaymentDate],[PostDate],[ReceiptId],[ReceivableCodeId],[ReceivableDueDate],[RejectionReasonId],[RemitToId],[Status],[SundryId],[Type])
    VALUES (S.[APGLTemplateId],S.[ApplyByPayable],S.[BillToId],S.[BranchId],S.[ClearingOption],S.[Comment],S.[ContractCurrencyId],S.[ContractSequenceNumber],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[ImportInvoice],S.[InstrumentTypeId],S.[IsFromPI],S.[IsScheduledFunding],S.[LegalEntityId],S.[LineofBusinessId],S.[LocationId],S.[OriginationType],S.[PayeeId],S.[PaymentDate],S.[PostDate],S.[ReceiptId],S.[ReceivableCodeId],S.[ReceivableDueDate],S.[RejectionReasonId],S.[RemitToId],S.[Status],S.[SundryId],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
