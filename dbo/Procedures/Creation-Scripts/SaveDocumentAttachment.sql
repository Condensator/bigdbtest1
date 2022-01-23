SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentAttachment]
(
 @val [dbo].[DocumentAttachment] READONLY
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
MERGE [dbo].[DocumentAttachments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AttachmentId]=S.[AttachmentId],[IsActive]=S.[IsActive],[IsModificationRequired]=S.[IsModificationRequired],[ModificationComment]=S.[ModificationComment],[ModificationReason]=S.[ModificationReason],[RowNumber]=S.[RowNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AttachmentId],[CreatedById],[CreatedTime],[DocumentInstanceId],[IsActive],[IsModificationRequired],[ModificationComment],[ModificationReason],[RowNumber])
    VALUES (S.[AttachmentId],S.[CreatedById],S.[CreatedTime],S.[DocumentInstanceId],S.[IsActive],S.[IsModificationRequired],S.[ModificationComment],S.[ModificationReason],S.[RowNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
