SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PersistGLEntriesForDiscounting]
(
@DiscountingJournalParam DiscountingJournalParam READONLY
,@DiscountingJournalDetailParam DiscountingJournalDetailParam READONLY
,@AmortIdsToUpdate AmortIdsToUpdate READONLY
,@BlendedItemDetailIdsToUpdate BlendedItemDetailIdsToUpdate READONLY
,@CapitalizedInterestsToUpdate CapitalizedInterestsToUpdate READONLY
,@IsReversal BIT
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
USING @DiscountingJournalParam JournalParam ON 1 = 0
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
FROM @DiscountingJournalDetailParam journalDetail
JOIN #GLJournal ON journalDetail.UniqueIdentifier = #GLJournal.UniqueIdentifier
UPDATE DAS
SET
IsGLPosted = CASE WHEN @IsReversal = 1 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM DiscountingAmortizationSchedules DAS
JOIN @AmortIdsToUpdate Amort ON DAS.Id = Amort.Id
UPDATE BID
SET
IsGLPosted = CASE WHEN @IsReversal = 1 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM BlendedItemDetails BID
JOIN @BlendedItemDetailIdsToUpdate BlendedDetail ON BID.Id = BlendedDetail.Id
UPDATE DCI
SET
GLJournalId = #GLJournal.GLJournalId,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM DiscountingCapitalizedInterests DCI
JOIN @CapitalizedInterestsToUpdate CaptitalizedInterestInfo ON DCI.Id = CaptitalizedInterestInfo.Id
JOIN #GLJournal ON CaptitalizedInterestInfo.UniqueIdentifier = #GLJournal.UniqueIdentifier
DROP TABLE #GLJournal
END

GO
