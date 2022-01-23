SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRecentTransaction]
(
 @val [dbo].[RecentTransaction] READONLY
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
MERGE [dbo].[RecentTransactions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[Description]=S.[Description],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ReferenceNumber]=S.[ReferenceNumber],[Transaction]=S.[Transaction],[TransactionName]=S.[TransactionName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[CustomerId],[Description],[EntityId],[EntityType],[ReferenceNumber],[Transaction],[TransactionName])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Description],S.[EntityId],S.[EntityType],S.[ReferenceNumber],S.[Transaction],S.[TransactionName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
