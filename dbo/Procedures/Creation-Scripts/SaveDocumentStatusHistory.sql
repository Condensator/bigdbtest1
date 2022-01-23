SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentStatusHistory]
(
 @val [dbo].[DocumentStatusHistory] READONLY
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
MERGE [dbo].[DocumentStatusHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsOfDate]=S.[AsOfDate],[Comment]=S.[Comment],[RowNumber]=S.[RowNumber],[StatusChangedById]=S.[StatusChangedById],[StatusId]=S.[StatusId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AsOfDate],[Comment],[CreatedById],[CreatedTime],[DocumentInstanceId],[RowNumber],[StatusChangedById],[StatusId])
    VALUES (S.[AsOfDate],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DocumentInstanceId],S.[RowNumber],S.[StatusChangedById],S.[StatusId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
