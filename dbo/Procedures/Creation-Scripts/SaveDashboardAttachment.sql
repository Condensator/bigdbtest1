SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDashboardAttachment]
(
 @val [dbo].[DashboardAttachment] READONLY
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
MERGE [dbo].[DashboardAttachments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Attachment_Content]=S.[Attachment_Content],[Attachment_Source]=S.[Attachment_Source],[Attachment_Type]=S.[Attachment_Type],[DocumentDescription]=S.[DocumentDescription],[DocumentName]=S.[DocumentName],[IsActive]=S.[IsActive],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Attachment_Content],[Attachment_Source],[Attachment_Type],[CreatedById],[CreatedTime],[DashboardProfileId],[DocumentDescription],[DocumentName],[IsActive],[Title])
    VALUES (S.[Attachment_Content],S.[Attachment_Source],S.[Attachment_Type],S.[CreatedById],S.[CreatedTime],S.[DashboardProfileId],S.[DocumentDescription],S.[DocumentName],S.[IsActive],S.[Title])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
