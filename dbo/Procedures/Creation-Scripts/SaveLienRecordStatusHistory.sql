SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLienRecordStatusHistory]
(
 @val [dbo].[LienRecordStatusHistory] READONLY
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
MERGE [dbo].[LienRecordStatusHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ExpiryDate]=S.[ExpiryDate],[FileDate]=S.[FileDate],[FileNumber]=S.[FileNumber],[FilingOffice]=S.[FilingOffice],[FilingStateId]=S.[FilingStateId],[FilingStatus]=S.[FilingStatus],[FilingType]=S.[FilingType],[HistoryDate]=S.[HistoryDate],[LienFilingId]=S.[LienFilingId],[OriginalFileDate]=S.[OriginalFileDate],[RecordStatus]=S.[RecordStatus],[RejectedReason]=S.[RejectedReason],[ResponseError]=S.[ResponseError],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ExpiryDate],[FileDate],[FileNumber],[FilingOffice],[FilingStateId],[FilingStatus],[FilingType],[HistoryDate],[LienFilingId],[OriginalFileDate],[RecordStatus],[RejectedReason],[ResponseError])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ExpiryDate],S.[FileDate],S.[FileNumber],S.[FilingOffice],S.[FilingStateId],S.[FilingStatus],S.[FilingType],S.[HistoryDate],S.[LienFilingId],S.[OriginalFileDate],S.[RecordStatus],S.[RejectedReason],S.[ResponseError])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
