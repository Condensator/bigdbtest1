SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveScenarioConfig]
(
 @val [dbo].[ScenarioConfig] READONLY
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
MERGE [dbo].[ScenarioConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Name]=S.[Name],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[XamlFile_Content]=S.[XamlFile_Content],[XamlFile_Source]=S.[XamlFile_Source],[XamlFile_Type]=S.[XamlFile_Type]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Name],[XamlFile_Content],[XamlFile_Source],[XamlFile_Type])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Name],S.[XamlFile_Content],S.[XamlFile_Source],S.[XamlFile_Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
