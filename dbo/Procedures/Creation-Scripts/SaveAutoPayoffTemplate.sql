SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoPayoffTemplate]
(
 @val [dbo].[AutoPayoffTemplate] READONLY
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
MERGE [dbo].[AutoPayoffTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivatePayoffQuote]=S.[ActivatePayoffQuote],[IsActive]=S.[IsActive],[Name]=S.[Name],[PayoffTemplateId]=S.[PayoffTemplateId],[PayoffTemplateTerminationTypeConfigId]=S.[PayoffTemplateTerminationTypeConfigId],[ThresholdDays]=S.[ThresholdDays],[ThresholdDaysOption]=S.[ThresholdDaysOption],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivatePayoffQuote],[CreatedById],[CreatedTime],[IsActive],[Name],[PayoffTemplateId],[PayoffTemplateTerminationTypeConfigId],[ThresholdDays],[ThresholdDaysOption])
    VALUES (S.[ActivatePayoffQuote],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Name],S.[PayoffTemplateId],S.[PayoffTemplateTerminationTypeConfigId],S.[ThresholdDays],S.[ThresholdDaysOption])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
