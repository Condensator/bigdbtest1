SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PersistGLJournalDetailsForIncome]
(
@JournalParam IncomeGLJournalParam READONLY
,@JournalDetailParam IncomeGLJournalDetailParam READONLY
,@LoanIncomesToUpdate IncomeGLUpdateInfo READONLY
,@LoanCapitalizedInterestsToUpdate IncomeGLUpdateInfo READONLY
,@LeaseIncomesToUpdate IncomeGLUpdateInfo READONLY
,@ReclassIncomesToUpdate SourceIdParam READONLY
,@AssetValueHistoriesToUpdate IncomeGLUpdateInfo READONLY
,@FloatRateIncomesToUpdate IncomeGLUpdateInfo READONLY
,@BlendedItemDetailsToUpdate IncomeGLUpdateInfo READONLY
,@BlendedIncomesToUpdate IncomeGLUpdateInfo READONLY
,@LeveragedLeaseAmortToUpdate IncomeGLUpdateInfo READONLY
,@NetValueUpdateInfo NetValueUpdateInfo READONLY
,@GuaranteedResidualPaymentIdsToUpdate SourceIdParam READONLY
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
,@IsGLReversal BIT
,@IsClearAccumulatedAccountsatPayoff BIT
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @IsGLPosted BIT = CASE WHEN @IsGLReversal = 1 THEN 0 ELSE 1 END;
DECLARE @ReclassOTP BIT = CASE WHEN @IsGLReversal = 1 THEN 0 ELSE 1 END;
CREATE TABLE #GLJournal
(
GLJournalId BIGINT,
UniqueId BIGINT,
PostDate DATETIME,
IsReversal BIT
);
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
OUTPUT inserted.Id, JournalParam.UniqueId, inserted.PostDate, inserted.IsReversalEntry  INTO #GLJournal;
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
JOIN #GLJournal ON journalDetail.UniqueId = #GLJournal.UniqueId
Update LoanIncomeSchedules
SET LoanIncomeSchedules.IsGLPosted = @IsGLPosted,UpdatedById=@CreatedById,UpdatedTime=@CreatedTime
FROM LoanIncomeSchedules
INNER JOIN @LoanIncomesToUpdate TVP ON LoanIncomeSchedules.Id = TVP.SourceId
Update LeaseIncomeSchedules
SET LeaseIncomeSchedules.IsGLPosted = @IsGLPosted,
LeaseIncomeSchedules.PostDate = CASE WHEN @IsGLReversal = 0 THEN TVP.PostDate ELSE NULL END,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM LeaseIncomeSchedules
INNER JOIN @LeaseIncomesToUpdate TVP ON LeaseIncomeSchedules.Id = TVP.SourceId
Update LeaseIncomeSchedules
SET
LeaseIncomeSchedules.IsReclassOTP=@ReclassOTP,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM LeaseIncomeSchedules
INNER JOIN @ReclassIncomesToUpdate TVP ON LeaseIncomeSchedules.Id = TVP.SourceId
Update LeaseFloatRateIncomes
SET LeaseFloatRateIncomes.IsGLPosted = @IsGLPosted,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM LeaseFloatRateIncomes
INNER JOIN @FloatRateIncomesToUpdate TVP ON LeaseFloatRateIncomes.Id = TVP.SourceId
UPDATE LeasePaymentSchedules
SET IsActive=@IsGLReversal,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM LeasePaymentSchedules
JOIN @GuaranteedResidualPaymentIdsToUpdate TVP ON LeasePaymentSchedules.Id = TVP.SourceId
Update BlendedItemDetails
SET BlendedItemDetails.PostDate = CASE WHEN @IsGLReversal = 0 THEN TVP.PostDate ELSE NULL END,
BlendedItemDetails.IsGLPosted = @IsGLPosted,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM BlendedItemDetails
INNER JOIN @BlendedItemDetailsToUpdate TVP ON BlendedItemDetails.Id = TVP.SourceId
Update BlendedIncomeSchedules
SET BlendedIncomeSchedules.PostDate = CASE WHEN @IsGLReversal = 0 THEN TVP.PostDate ELSE NULL END,
BlendedIncomeSchedules.ReversalPostDate = CASE WHEN @IsGLReversal = 1 THEN TVP.PostDate ELSE NULL END,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM BlendedIncomeSchedules
INNER JOIN @BlendedIncomesToUpdate TVP ON BlendedIncomeSchedules.Id = TVP.SourceId
Update LeveragedLeaseAmorts
SET LeveragedLeaseAmorts.IsGLPosted = @IsGLPosted,
UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM LeveragedLeaseAmorts
INNER JOIN @LeveragedLeaseAmortToUpdate TVP ON LeveragedLeaseAmorts.Id = TVP.SourceId
Update AssetValueHistories
SET
AssetValueHistories.PostDate = CASE WHEN @IsGLReversal = 0 THEN TVP.PostDate ELSE NULL END
,AssetValueHistories.GLJournalId = CASE WHEN @IsGLReversal = 0 THEN GLJournal.GLJournalId ELSE NULL END
,AssetValueHistories.ReversalPostDate = CASE WHEN @IsGLReversal = 1 THEN TVP.PostDate ELSE NULL END
,AssetValueHistories.ReversalGLJournalId = CASE WHEN @IsGLReversal = 1 THEN GLJournal.GLJournalId ELSE NULL END
,UpdatedById=@CreatedById,UpdatedTime=@CreatedTime
FROM AssetValueHistories
INNER JOIN @AssetValueHistoriesToUpdate TVP ON AssetValueHistories.Id = TVP.SourceId
INNER JOIN #GLJournal GLJournal ON TVP.UniqueId = GLJournal.UniqueId
Update AssetValueHistories
SET AssetValueHistories.NetValue_Amount =  TVP.NetValue
,AssetValueHistories.IsCleared = TVP.IsCleared
,UpdatedById=@CreatedById,
UpdatedTime=@CreatedTime
FROM AssetValueHistories
INNER JOIN @NetValueUpdateInfo TVP ON AssetValueHistories.Id = TVP.SourceId
Update LoanCapitalizedInterests
SET LoanCapitalizedInterests.GLJournalId = CASE WHEN @IsGLReversal = 0 THEN GLJournal.GLJournalId ELSE NULL END
,UpdatedById=@CreatedById
,UpdatedTime=@CreatedTime
FROM LoanCapitalizedInterests
INNER JOIN @LoanCapitalizedInterestsToUpdate TVP ON LoanCapitalizedInterests.Id = TVP.SourceId
INNER JOIN #GLJournal GLJournal ON TVP.UniqueId = GLJournal.UniqueId
DROP TABLE #GLJournal
SET NOCOUNT OFF;
END

GO
