SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReportPreferenceConfig]
(
 @val [dbo].[ReportPreferenceConfig] READONLY
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
MERGE [dbo].[ReportPreferenceConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllowGroup]=S.[AllowGroup],[AllowSort]=S.[AllowSort],[AllowSubTotal]=S.[AllowSubTotal],[GroupOrder]=S.[GroupOrder],[Order]=S.[Order],[ReportColumn]=S.[ReportColumn],[ReportColumnLabel]=S.[ReportColumnLabel],[ReportName]=S.[ReportName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllowGroup],[AllowSort],[AllowSubTotal],[CreatedById],[CreatedTime],[GroupOrder],[Order],[ReportColumn],[ReportColumnLabel],[ReportName])
    VALUES (S.[AllowGroup],S.[AllowSort],S.[AllowSubTotal],S.[CreatedById],S.[CreatedTime],S.[GroupOrder],S.[Order],S.[ReportColumn],S.[ReportColumnLabel],S.[ReportName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
