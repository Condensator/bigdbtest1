SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReportTemplate]
(
 @val [dbo].[ReportTemplate] READONLY
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
MERGE [dbo].[ReportTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ColumnOrder]=S.[ColumnOrder],[ColumnsToHide]=S.[ColumnsToHide],[Culture]=S.[Culture],[GroupBy]=S.[GroupBy],[GroupByLabel]=S.[GroupByLabel],[Name]=S.[Name],[NonAccessableFieldList]=S.[NonAccessableFieldList],[OutputFormat]=S.[OutputFormat],[Privacy]=S.[Privacy],[SortBy]=S.[SortBy],[SortOrder]=S.[SortOrder],[TotalFieldsToHide]=S.[TotalFieldsToHide],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ColumnOrder],[ColumnsToHide],[CreatedById],[CreatedTime],[Culture],[GroupBy],[GroupByLabel],[Name],[NonAccessableFieldList],[OutputFormat],[Privacy],[SortBy],[SortOrder],[TotalFieldsToHide],[Type])
    VALUES (S.[ColumnOrder],S.[ColumnsToHide],S.[CreatedById],S.[CreatedTime],S.[Culture],S.[GroupBy],S.[GroupByLabel],S.[Name],S.[NonAccessableFieldList],S.[OutputFormat],S.[Privacy],S.[SortBy],S.[SortOrder],S.[TotalFieldsToHide],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
