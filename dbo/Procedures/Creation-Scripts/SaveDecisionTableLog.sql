SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDecisionTableLog]
(
 @val [dbo].[DecisionTableLog] READONLY
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
MERGE [dbo].[DecisionTableLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Conditions]=S.[Conditions],[DecisionTableTypeConfigName]=S.[DecisionTableTypeConfigName],[EntityTypeId]=S.[EntityTypeId],[Name]=S.[Name],[Result]=S.[Result],[RuleName]=S.[RuleName],[SourceId]=S.[SourceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Conditions],[CreatedById],[CreatedTime],[DecisionTableTypeConfigName],[EntityTypeId],[Name],[Result],[RuleName],[SourceId])
    VALUES (S.[Conditions],S.[CreatedById],S.[CreatedTime],S.[DecisionTableTypeConfigName],S.[EntityTypeId],S.[Name],S.[Result],S.[RuleName],S.[SourceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
