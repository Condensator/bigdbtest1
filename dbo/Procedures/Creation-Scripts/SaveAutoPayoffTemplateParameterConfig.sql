SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoPayoffTemplateParameterConfig]
(
 @val [dbo].[AutoPayoffTemplateParameterConfig] READONLY
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
MERGE [dbo].[AutoPayoffTemplateParameterConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Collection]=S.[Collection],[DataSource]=S.[DataSource],[Description]=S.[Description],[IsActive]=S.[IsActive],[Name]=S.[Name],[Order]=S.[Order],[QualificationQuery]=S.[QualificationQuery],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Collection],[CreatedById],[CreatedTime],[DataSource],[Description],[IsActive],[Name],[Order],[QualificationQuery],[Type])
    VALUES (S.[Collection],S.[CreatedById],S.[CreatedTime],S.[DataSource],S.[Description],S.[IsActive],S.[Name],S.[Order],S.[QualificationQuery],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
