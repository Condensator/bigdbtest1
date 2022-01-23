SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAttachmentForDoc]
(
 @val [dbo].[AttachmentForDoc] READONLY
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
MERGE [dbo].[AttachmentForDocs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentId]=S.[AttachmentId],[GeneratedRawFile_Content]=S.[GeneratedRawFile_Content],[GeneratedRawFile_Source]=S.[GeneratedRawFile_Source],[GeneratedRawFile_Type]=S.[GeneratedRawFile_Type],[IsGenerated]=S.[IsGenerated],[IsPacked]=S.[IsPacked],[IsSample]=S.[IsSample],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentId],[CreatedById],[CreatedTime],[GeneratedRawFile_Content],[GeneratedRawFile_Source],[GeneratedRawFile_Type],[IsGenerated],[IsPacked],[IsSample])
    VALUES (S.[AttachmentId],S.[CreatedById],S.[CreatedTime],S.[GeneratedRawFile_Content],S.[GeneratedRawFile_Source],S.[GeneratedRawFile_Type],S.[IsGenerated],S.[IsPacked],S.[IsSample])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
