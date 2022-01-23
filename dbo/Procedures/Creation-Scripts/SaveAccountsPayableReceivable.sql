SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAccountsPayableReceivable]
(
 @val [dbo].[AccountsPayableReceivable] READONLY
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
MERGE [dbo].[AccountsPayableReceivables] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToApply_Amount]=S.[AmountToApply_Amount],[AmountToApply_Currency]=S.[AmountToApply_Currency],[IsActive]=S.[IsActive],[ReceivableId]=S.[ReceivableId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountsPayableId],[AmountToApply_Amount],[AmountToApply_Currency],[CreatedById],[CreatedTime],[IsActive],[ReceivableId])
    VALUES (S.[AccountsPayableId],S.[AmountToApply_Amount],S.[AmountToApply_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[ReceivableId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
