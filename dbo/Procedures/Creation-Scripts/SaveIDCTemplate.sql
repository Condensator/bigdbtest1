SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveIDCTemplate]
(
 @val [dbo].[IDCTemplate] READONLY
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
MERGE [dbo].[IDCTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BlendedItemCodeId]=S.[BlendedItemCodeId],[CeilingPercent]=S.[CeilingPercent],[FloorPercent]=S.[FloorPercent],[GLConfigurationId]=S.[GLConfigurationId],[IDCTemplateName]=S.[IDCTemplateName],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[PortfolioId]=S.[PortfolioId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BlendedItemCodeId],[CeilingPercent],[CreatedById],[CreatedTime],[FloorPercent],[GLConfigurationId],[IDCTemplateName],[IsActive],[IsDefault],[PortfolioId])
    VALUES (S.[BlendedItemCodeId],S.[CeilingPercent],S.[CreatedById],S.[CreatedTime],S.[FloorPercent],S.[GLConfigurationId],S.[IDCTemplateName],S.[IsActive],S.[IsDefault],S.[PortfolioId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
