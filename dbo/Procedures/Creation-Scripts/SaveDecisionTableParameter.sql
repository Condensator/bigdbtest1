SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDecisionTableParameter]
(
 @val [dbo].[DecisionTableParameter] READONLY
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
MERGE [dbo].[DecisionTableParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DataType]=S.[DataType],[Description]=S.[Description],[DirectionOfUse]=S.[DirectionOfUse],[EntityId]=S.[EntityId],[IsActive]=S.[IsActive],[IsSystemDefined]=S.[IsSystemDefined],[Name]=S.[Name],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserFriendlyName]=S.[UserFriendlyName],[ValueExpression]=S.[ValueExpression]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DataType],[Description],[DirectionOfUse],[EntityId],[IsActive],[IsSystemDefined],[Name],[UserFriendlyName],[ValueExpression])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DataType],S.[Description],S.[DirectionOfUse],S.[EntityId],S.[IsActive],S.[IsSystemDefined],S.[Name],S.[UserFriendlyName],S.[ValueExpression])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
