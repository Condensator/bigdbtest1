SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneTimeACHRequest]
(
 @val [dbo].[OneTimeACHRequest] READONLY
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
MERGE [dbo].[OneTimeACHRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BankAccountId]=S.[BankAccountId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[IsActive]=S.[IsActive],[Status]=S.[Status],[TotalAmount_Amount]=S.[TotalAmount_Amount],[TotalAmount_Currency]=S.[TotalAmount_Currency],[TotalAmountToPay_Amount]=S.[TotalAmountToPay_Amount],[TotalAmountToPay_Currency]=S.[TotalAmountToPay_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BankAccountId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[IsActive],[Status],[TotalAmount_Amount],[TotalAmount_Currency],[TotalAmountToPay_Amount],[TotalAmountToPay_Currency])
    VALUES (S.[BankAccountId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[IsActive],S.[Status],S.[TotalAmount_Amount],S.[TotalAmount_Currency],S.[TotalAmountToPay_Amount],S.[TotalAmountToPay_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
