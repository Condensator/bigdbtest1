SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHSchedule]
(
 @val [dbo].[ACHSchedule] READONLY
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
MERGE [dbo].[ACHSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHAccountId]=S.[ACHAccountId],[ACHAmount_Amount]=S.[ACHAmount_Amount],[ACHAmount_Currency]=S.[ACHAmount_Currency],[ACHPaymentNumber]=S.[ACHPaymentNumber],[BankAccountPaymentThresholdId]=S.[BankAccountPaymentThresholdId],[FileGenerationDate]=S.[FileGenerationDate],[IsActive]=S.[IsActive],[IsPreACHNotificationCreated]=S.[IsPreACHNotificationCreated],[PaymentType]=S.[PaymentType],[ReceivableId]=S.[ReceivableId],[SettlementDate]=S.[SettlementDate],[Status]=S.[Status],[StopPayment]=S.[StopPayment],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHAccountId],[ACHAmount_Amount],[ACHAmount_Currency],[ACHPaymentNumber],[BankAccountPaymentThresholdId],[ContractBillingId],[CreatedById],[CreatedTime],[FileGenerationDate],[IsActive],[IsPreACHNotificationCreated],[PaymentType],[ReceivableId],[SettlementDate],[Status],[StopPayment])
    VALUES (S.[ACHAccountId],S.[ACHAmount_Amount],S.[ACHAmount_Currency],S.[ACHPaymentNumber],S.[BankAccountPaymentThresholdId],S.[ContractBillingId],S.[CreatedById],S.[CreatedTime],S.[FileGenerationDate],S.[IsActive],S.[IsPreACHNotificationCreated],S.[PaymentType],S.[ReceivableId],S.[SettlementDate],S.[Status],S.[StopPayment])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
