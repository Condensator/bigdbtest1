SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateJournalEntriesForTaxDepExpenseGL]
(
@JournalParam TaxDepJournalParam READONLY
,@JournalDetailParam TaxDepJournalDetailParam READONLY
,@TaxDepGlDetails TaxDepGlDetails READONLY
,@IsReversal Bit
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #GLJournal
(
GLJournalId BIGINT,
RecordCount BIGINT,
PostDate DATETIME,
IsReversal BIT,
ContractId BIGINT,
)
CREATE TABLE #TaxDepAmortGL
(
TaxDepAmortGLHeaderId BIGINT,
RecordCount BIGINT,
ContractId BIGINT
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
OUTPUT inserted.Id, JournalParam.RecordCount, inserted.PostDate, inserted.IsReversalEntry,JournalParam.ContractId INTO #GLJournal;
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
JOIN #GLJournal ON journalDetail.RecordCount = #GLJournal.RecordCount
MERGE TaxDepAmortizationGLHeaders TaxDepAmortGLHeaders
USING #GLJournal GlJournal ON 1 != 1
WHEN NOT MATCHED THEN
INSERT
(EntityId,EntityType,PostDate,IsActive,CreatedById,CreatedTime,[UpdatedById],[UpdatedTime],GLJournalId)
VALUES(ContractId
,'Contract'
,PostDate
,CAST(1 AS BIT)
,@CreatedById
,@CreatedTime
,NULL
,NULL
,GLJournalId)
OUTPUT INSERTED.Id,GlJournal.RecordCount,GlJournal.ContractId INTO #TaxDepAmortGL;
INSERT INTO TaxDepAmortizationGLDetails
(CreatedById,CreatedTime,TaxDepAmortizationGLHeaderId,TaxDepAmortizationDetailId)
SELECT
@CreatedById
,@CreatedTime
,#TaxDepAmortGL.TaxDepAmortGLHeaderId
,TD.TaxDepAmortDetailId
FROM #TaxDepAmortGL
JOIN @TaxDepGlDetails TD ON TD.RecordCount = #TaxDepAmortGL.recordCount AND TD.ContractId = #TaxDepAmortGL.ContractId
UPDATE TDAD SET  IsGLPosted = CASE WHEN @IsReversal = 1 THEN 0 ELSE 1 END , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM TaxDepAmortizationDetails TDAD
JOIN @TaxDepGlDetails tmpTaxDepGL ON TDAD.Id = tmpTaxDepGL.TaxDepAmortDetailId;
DROP TABLE #GLJournal
DROP TABLE #TaxDepAmortGL
SET NOCOUNT OFF;
END

GO
