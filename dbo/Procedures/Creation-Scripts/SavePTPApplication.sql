SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePTPApplication]
(
 @val [dbo].[PTPApplication] READONLY
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
MERGE [dbo].[PTPApplications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountApplied_Amount]=S.[AmountApplied_Amount],[AmountApplied_Currency]=S.[AmountApplied_Currency],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[IsActive]=S.[IsActive],[PaymentPromiseId]=S.[PaymentPromiseId],[ReceiptId]=S.[ReceiptId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountApplied_Amount],[AmountApplied_Currency],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[IsActive],[PaymentPromiseId],[ReceiptId])
    VALUES (S.[AmountApplied_Amount],S.[AmountApplied_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IsActive],S.[PaymentPromiseId],S.[ReceiptId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
