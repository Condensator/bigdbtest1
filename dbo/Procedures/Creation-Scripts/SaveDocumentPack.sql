SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentPack]
(
 @val [dbo].[DocumentPack] READONLY
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
MERGE [dbo].[DocumentPacks] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentId]=S.[AttachmentId],[Comment]=S.[Comment],[CreatedDate]=S.[CreatedDate],[EmailRowNumber]=S.[EmailRowNumber],[EmailSentById]=S.[EmailSentById],[EmailSentTime]=S.[EmailSentTime],[EnabledForESignature]=S.[EnabledForESignature],[IsActive]=S.[IsActive],[Name]=S.[Name],[PackedById]=S.[PackedById],[PackedFromId]=S.[PackedFromId],[StatusChangedById]=S.[StatusChangedById],[StatusDate]=S.[StatusDate],[StatusId]=S.[StatusId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentId],[Comment],[CreatedById],[CreatedDate],[CreatedTime],[DocumentHeaderId],[EmailRowNumber],[EmailSentById],[EmailSentTime],[EnabledForESignature],[IsActive],[Name],[PackedById],[PackedFromId],[StatusChangedById],[StatusDate],[StatusId])
    VALUES (S.[AttachmentId],S.[Comment],S.[CreatedById],S.[CreatedDate],S.[CreatedTime],S.[DocumentHeaderId],S.[EmailRowNumber],S.[EmailSentById],S.[EmailSentTime],S.[EnabledForESignature],S.[IsActive],S.[Name],S.[PackedById],S.[PackedFromId],S.[StatusChangedById],S.[StatusDate],S.[StatusId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
