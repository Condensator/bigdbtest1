SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveFileStore]
(
 @val [dbo].[FileStore] READONLY
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
MERGE [dbo].[FileStores] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccessKey]=S.[AccessKey],[Content]=S.[Content],[ExtStoreReference]=S.[ExtStoreReference],[FileType]=S.[FileType],[GUID]=S.[GUID],[IsActive]=S.[IsActive],[IsContentProcessed]=S.[IsContentProcessed],[IsPreserveContentInLocal]=S.[IsPreserveContentInLocal],[Source]=S.[Source],[SourceEntity]=S.[SourceEntity],[SourceEntityId]=S.[SourceEntityId],[SourceSystem]=S.[SourceSystem],[StorageSystem]=S.[StorageSystem],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccessKey],[Content],[CreatedById],[CreatedTime],[ExtStoreReference],[FileType],[GUID],[IsActive],[IsContentProcessed],[IsPreserveContentInLocal],[Source],[SourceEntity],[SourceEntityId],[SourceSystem],[StorageSystem])
    VALUES (S.[AccessKey],S.[Content],S.[CreatedById],S.[CreatedTime],S.[ExtStoreReference],S.[FileType],S.[GUID],S.[IsActive],S.[IsContentProcessed],S.[IsPreserveContentInLocal],S.[Source],S.[SourceEntity],S.[SourceEntityId],S.[SourceSystem],S.[StorageSystem])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
