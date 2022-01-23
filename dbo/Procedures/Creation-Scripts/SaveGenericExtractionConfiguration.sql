SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGenericExtractionConfiguration]
(
 @val [dbo].[GenericExtractionConfiguration] READONLY
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
MERGE [dbo].[GenericExtractionConfigurations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CreateSubFolderPerDataSet]=S.[CreateSubFolderPerDataSet],[CustomFileExtension]=S.[CustomFileExtension],[CustomHeaderData]=S.[CustomHeaderData],[Delimiter]=S.[Delimiter],[FileExtension]=S.[FileExtension],[FileNameFormat]=S.[FileNameFormat],[FilePath]=S.[FilePath],[FileSplitThreshold]=S.[FileSplitThreshold],[IsHeaderRequired]=S.[IsHeaderRequired],[IsTriggerFileRequired]=S.[IsTriggerFileRequired],[MessageNotificationComponent]=S.[MessageNotificationComponent],[TriggerFileName]=S.[TriggerFileName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UseFieldEnclosure]=S.[UseFieldEnclosure]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CreateSubFolderPerDataSet],[CustomFileExtension],[CustomHeaderData],[Delimiter],[FileExtension],[FileNameFormat],[FilePath],[FileSplitThreshold],[Id],[IsHeaderRequired],[IsTriggerFileRequired],[MessageNotificationComponent],[TriggerFileName],[UseFieldEnclosure])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CreateSubFolderPerDataSet],S.[CustomFileExtension],S.[CustomHeaderData],S.[Delimiter],S.[FileExtension],S.[FileNameFormat],S.[FilePath],S.[FileSplitThreshold],S.[Id],S.[IsHeaderRequired],S.[IsTriggerFileRequired],S.[MessageNotificationComponent],S.[TriggerFileName],S.[UseFieldEnclosure])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
