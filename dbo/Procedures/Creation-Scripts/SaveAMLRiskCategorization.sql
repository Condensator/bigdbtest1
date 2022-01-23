SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAMLRiskCategorization]
(
 @val [dbo].[AMLRiskCategorization] READONLY
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
MERGE [dbo].[AMLRiskCategorizations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Adjustment]=S.[Adjustment],[AMLRiskCategoryConfigId]=S.[AMLRiskCategoryConfigId],[Category]=S.[Category],[IsActive]=S.[IsActive],[Point]=S.[Point],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Adjustment],[AMLRiskAssessmentId],[AMLRiskCategoryConfigId],[Category],[CreatedById],[CreatedTime],[IsActive],[Point])
    VALUES (S.[Adjustment],S.[AMLRiskAssessmentId],S.[AMLRiskCategoryConfigId],S.[Category],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Point])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
