SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEntityConfig]
(
 @val [dbo].[EntityConfig] READONLY
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
MERGE [dbo].[EntityConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowBulkUpdate]=S.[AllowBulkUpdate],[EntitySummaryExpression]=S.[EntitySummaryExpression],[Name]=S.[Name],[NaturalIdProperty]=S.[NaturalIdProperty],[TransactionForOcr]=S.[TransactionForOcr],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserFriendlyName]=S.[UserFriendlyName]
WHEN NOT MATCHED THEN
	INSERT ([AllowBulkUpdate],[CreatedById],[CreatedTime],[EntitySummaryExpression],[Name],[NaturalIdProperty],[TransactionForOcr],[UserFriendlyName])
    VALUES (S.[AllowBulkUpdate],S.[CreatedById],S.[CreatedTime],S.[EntitySummaryExpression],S.[Name],S.[NaturalIdProperty],S.[TransactionForOcr],S.[UserFriendlyName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
