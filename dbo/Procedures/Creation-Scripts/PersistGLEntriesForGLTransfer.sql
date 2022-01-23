SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PersistGLEntriesForGLTransfer]
(
@GLTransferJournalParam GLTransferJournalParam READONLY
,@GLTransferJournalDetailParam GLTransferJournalDetailParam READONLY
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #GLJournal
(
GLJournalId BIGINT,
UniqueIdentifier BIGINT
)
MERGE GLJournals GLJournal
USING @GLTransferJournalParam JournalParam ON 1 = 0
WHEN NOT MATCHED THEN
INSERT ([PostDate]
,[IsManualEntry]
,[IsReversalEntry]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[LegalEntityId])
VALUES(PostDate
,IsManualEntry
,IsReversalEntry
,@CreatedById
,@CreatedTime
,NULL
,NULL
,LegalEntityId)
OUTPUT inserted.Id, JournalParam.UniqueIdentifier INTO #GLJournal;
INSERT INTO [dbo].[GLJournalDetails]
([EntityId]
,[EntityType]
,[Amount_Amount]
,[Amount_Currency]
,[IsDebit]
,[GLAccountNumber]
,[Description]
,[SourceId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[GLAccountId]
,[GLTemplateDetailId]
,[MatchingGLTemplateDetailId]
,[LineofBusinessId]
,[ExportJobId]
,[GLJournalId]
,[IsActive]
,[InstrumentTypeGLAccountId])
SELECT
EntityId
,EntityType
,Amount
,Currency
,IsDebit
,GLAccountNumber
,Description
,journalDetail.SourceId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLAccountId
,GLTemplateDetailId
,MatchingGLTemplateDetailId
,LineofBusinessId
,NULL
,#GLJournal.GLJournalId
,IsActive
,InstrumentTypeGLAccountId
FROM @GLTransferJournalDetailParam journalDetail
JOIN #GLJournal ON journalDetail.UniqueIdentifier = #GLJournal.UniqueIdentifier
DROP TABLE #GLJournal
SET NOCOUNT OFF;
END

GO
