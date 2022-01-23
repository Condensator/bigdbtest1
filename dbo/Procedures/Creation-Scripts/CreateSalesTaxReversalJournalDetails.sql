SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateSalesTaxReversalJournalDetails]
(
@SalesTaxReversalJournalParam SalesTaxReversalJournalParam READONLY
,@SalesTaxReversalJournalDetailParam SalesTaxReversalJournalDetailParam READONLY
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
USING @SalesTaxReversalJournalParam JournalParam ON 1 != 1
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
FROM @SalesTaxReversalJournalDetailParam journalDetail
JOIN #GLJournal ON journalDetail.SourceId = #GLJournal.SourceId
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

GO
