SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateJournalDetailsInBatch]
(
@JournalParam JournalParam READONLY
,@JournalDetailParam JournalDetailParam READONLY
,@JobName NVARCHAR(MAX)
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #GLJournal
(
GLJournalId BIGINT,
SourceId BIGINT,
PostDate DATETIME,
IsReversal BIT
)
MERGE GLJournals GLJournal
USING @JournalParam JournalParam ON 1 != 1
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
OUTPUT inserted.Id, JournalParam.SourceId, inserted.PostDate, inserted.IsReversalEntry INTO #GLJournal;
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
FROM @JournalDetailParam journalDetail
JOIN #GLJournal ON journalDetail.SourceId = #GLJournal.SourceId
IF(@JobName = 'PostReceivableToGL')
BEGIN
UPDATE Receivables SET IsGLPosted =  CONVERT(BIT,  journal.IsReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM Receivables
JOIN #GLJournal journal ON Receivables.Id = journal.SourceId
INSERT INTO [dbo].[ReceivableGLJournals]
([PostDate]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[GLJournalId]
,[ReversalGLJournalOfId]
,[ReceivableId])
SELECT
PostDate
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLJournalId
,NULL
,SourceId
FROM #GLJournal
END
ELSE IF(@JobName = 'PostReceivableTaxToGL')
BEGIN
UPDATE ReceivableTaxes SET IsGLPosted =  CONVERT(BIT,  journal.IsReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxes
JOIN #GLJournal journal ON ReceivableTaxes.Id = journal.SourceId
UPDATE ReceivableTaxDetails
SET IsGLPosted = CONVERT(BIT,  journal.IsReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableTaxDetails
JOIN ReceivableTaxes ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId
JOIN #GLJournal journal ON ReceivableTaxes.Id = journal.SourceId
INSERT INTO [dbo].[ReceivableTaxGLs]
([PostDate]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[GLJournalId]
,[ReceivableTaxId]
,[IsReversal])
SELECT
PostDate
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLJournalId
,SourceId
,IsReversal
FROM #GLJournal
END
ELSE IF(@JobName = 'DeferredTaxToGL')
BEGIN
UPDATE DeferredTaxes SET IsGLPosted =  CONVERT(BIT,  journal.IsReversal -1), UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM DeferredTaxes
JOIN #GLJournal journal ON DeferredTaxes.Id = journal.SourceId
END
ELSE IF(@JobName in ('PostPayableToGL', 'PayableGL'))
BEGIN
UPDATE Payables SET IsGLPosted = 1, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM Payables
JOIN #GLJournal journal ON Payables.Id = journal.SourceId
INSERT INTO [dbo].[PayableGLJournals]
([PostDate]
,[IsReversal]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[GLJournalId]
,[PayableId])
SELECT
PostDate
,IsReversal
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLJournalId
,SourceId
FROM #GLJournal
END
DROP TABLE #GLJournal
SET NOCOUNT OFF;
END

GO
