SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAttachment]
(
 @val [dbo].[Attachment] READONLY
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
MERGE [dbo].[Attachments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachedById]=S.[AttachedById],[AttachedDate]=S.[AttachedDate],[Description]=S.[Description],[File_Content]=S.[File_Content],[File_Source]=S.[File_Source],[File_Type]=S.[File_Type],[SourceId]=S.[SourceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachedById],[AttachedDate],[CreatedById],[CreatedTime],[Description],[File_Content],[File_Source],[File_Type],[SourceId])
    VALUES (S.[AttachedById],S.[AttachedDate],S.[CreatedById],S.[CreatedTime],S.[Description],S.[File_Content],S.[File_Source],S.[File_Type],S.[SourceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
