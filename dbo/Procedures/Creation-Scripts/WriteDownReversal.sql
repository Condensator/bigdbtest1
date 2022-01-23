SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[WriteDownReversal]
(
@ContractId BIGINT
,@Status NVARCHAR(15)
,@WriteDownReason NVARCHAR(15)
,@WriteDownDate DATETIME
,@PostDate DATETIME
,@SourceId BIGINT
,@SourceModule NVARCHAR(50)
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
,@JournalParam WriteDownJournalParam READONLY
,@JournalDetailParam WriteDownJournalDetailParam READONLY
,@AmountToBeCleared DECIMAL
,@IsAssetWriteDown BIT
)
AS
BEGIN
SET NOCOUNT ON
--DECLARE @ContractId BIGINT = 60473
--DECLARE @Status NVARCHAR(15) = 'Approved'
--DECLARE @WriteDownDate DATETIME = '11/02/2016'
--DECLARE @PostDate DATETIME = '11/02/2016'
--DECLARE @CreatedById BIGINT = 1
--DECLARE @CreatedTime DATETIMEOFFSET = GETDATE()
--DECLARE @JournalParam WriteDownJournalParam READONLY = NULL
--DECLARE @JournalDetailParam WriteDownJournalDetailParam READONLY = NULL
DECLARE @WriteDownAmount DECIMAL(18,2)
DECLARE @WriteDownId BIGINT
DECLARE @WriteDownCurrency NVARCHAR(3)
DECLARE @ContractType NVARCHAR(50)
DECLARE @LeaseFinanceId BIGINT = NULL
DECLARE @LoanFinanceId BIGINT = NULL
DECLARE @GLTemplateId BIGINT
DECLARE @RecoveryGLTemplateId BIGINT
DECLARE @RecoveryReceivableCodeId BIGINT
CREATE TABLE #WriteDownDetails
(
ContractId bigint,
AssetId bigint,
WriteDownAmount_Amount decimal(16,2),
LeaseComponentWriteDownAmount_Amount decimal(16,2),
NonLeaseComponentWriteDownAmount_Amount decimal(16,2),
NetInvestmentWithBlended_Amount decimal(16,2),
NetInvestmentWithReserve_Amount decimal(16,2),
GrossWritedown_Amount decimal(16,2),
NetWritedown_Amount decimal(16,2)
)
SELECT TOP 1
@WriteDownCurrency = WriteDownAmount_Currency,
@ContractType = ContractType,
@LeaseFinanceId = LeaseFinanceId,
@LoanFinanceId = LoanFinanceId,
@GLTemplateId = GLTemplateId,
@RecoveryGLTemplateId = RecoveryGLTemplateId,
@RecoveryReceivableCodeId = RecoveryReceivableCodeId
FROM WriteDowns
WHERE ContractId = @ContractId
AND Status = @status
AND IsActive = 1
IF (@AmountToBeCleared != 0.0)
INSERT INTO #WriteDownDetails
VALUES (@ContractId
, NULL
, @AmountToBeCleared
, @AmountToBeCleared
, 0
, 0
, 0
, 0
, 0)
ELSE
INSERT INTO #WriteDownDetails
SELECT
WriteDowns.ContractId,
AssetId,
SUM(WriteDownAssetDetails.WriteDownAmount_Amount),
SUM(WriteDownAssetDetails.LeaseComponentWriteDownAmount_Amount),
SUM(WriteDownAssetDetails.NonLeaseComponentWriteDownAmount_Amount),
SUM(WriteDownAssetDetails.NetInvestmentWithBlended_Amount),
SUM(WriteDownAssetDetails.NetInvestmentWithReserve_Amount),
SUM(WriteDownAssetDetails.GrossWritedown_Amount),
SUM(WriteDownAssetDetails.NetWritedown_Amount)
FROM WriteDowns
JOIN WriteDownAssetDetails
ON WriteDowns.Id = WriteDownAssetDetails.WriteDownId
WHERE WriteDowns.ContractId = @ContractId
AND WriteDownAssetDetails.IsActive = 1
AND Status = @Status
GROUP BY	WriteDowns.ContractId,
WriteDownAssetDetails.AssetId
INSERT INTO WriteDowns (WriteDownDate
, WriteDownAmount_Amount
, WriteDownAmount_Currency
, IsAssetWriteDown
, IsRecovery
, PostDate
, ContractType
, IsActive
, Status
, NetInvestmentWithBlended_Amount
, NetInvestmentWithBlended_Currency
, NetInvestmentWithReserve_Amount
, NetInvestmentWithReserve_Currency
, GrossWritedown_Amount
, GrossWritedown_Currency
, NetWritedown_Amount
, NetWritedown_Currency
, WriteDownReason
, SourceId
, SourceModule
, CreatedById
, CreatedTime
, GLTemplateId
, RecoveryGLTemplateId
, RecoveryReceivableCodeId
, ContractId
, LeaseFinanceId
, LoanFinanceId)
SELECT
@WriteDownDate,
-1 * SUM(WriteDownAmount_Amount),
@WriteDownCurrency,
1,
0,
@PostDate,
@ContractType,
1,
@Status,
-1 * SUM(NetInvestmentWithBlended_Amount),
@WriteDownCurrency,
-1 * SUM(NetInvestmentWithReserve_Amount),
@WriteDownCurrency,
-1 * SUM(GrossWritedown_Amount),
@WriteDownCurrency,
-1 * SUM(NetWritedown_Amount),
@WriteDownCurrency,
@WriteDownReason,
@SourceId,
@SourceModule,
@CreatedById,
@CreatedTime,
@GLTemplateId,
@RecoveryGLTemplateId,
@RecoveryReceivableCodeId,
@ContractId,
@LeaseFinanceId,
@LoanFinanceId
FROM #WriteDownDetails
GROUP BY ContractId
SET @WriteDownId = SCOPE_IDENTITY();
IF (@IsAssetWriteDown = 1)
INSERT INTO WriteDownAssetDetails (WriteDownAmount_Amount
, WriteDownAmount_Currency
, IsActive
, LeaseComponentWriteDownAmount_Amount
, LeaseComponentWriteDownAmount_Currency
, NonLeaseComponentWriteDownAmount_Amount
, NonLeaseComponentWriteDownAmount_Currency
, NetInvestmentWithBlended_Amount
, NetInvestmentWithBlended_Currency
, NetInvestmentWithReserve_Amount
, NetInvestmentWithReserve_Currency
, GrossWritedown_Amount
, GrossWritedown_Currency
, NetWritedown_Amount
, NetWritedown_Currency
, CreatedById
, CreatedTime
, AssetId
, WriteDownId)
SELECT
-1 * WriteDownAmount_Amount,
@WriteDownCurrency,
1,
-1 * LeaseComponentWriteDownAmount_Amount,
@WriteDownCurrency,
-1 * NonLeaseComponentWriteDownAmount_Amount,
@WriteDownCurrency,
-1 * NetInvestmentWithBlended_Amount,
@WriteDownCurrency,
-1 * NetInvestmentWithReserve_Amount,
@WriteDownCurrency,
-1 * GrossWritedown_Amount,
@WriteDownCurrency,
-1 * NetWritedown_Amount,
@WriteDownCurrency,
@createdById,
@CreatedTime,
AssetId,
@WriteDownId
FROM #WriteDownDetails
/* Writedown GL portion */
CREATE TABLE #GLJournal (
GLJournalId BIGINT,
SourceId BIGINT,
PostDate DATETIME,
IsReversal BIT
)
MERGE GLJournals GLJournal
USING @JournalParam JournalParam
ON 1 != 1
WHEN NOT MATCHED
THEN INSERT ([PostDate]
, [IsManualEntry]
, [IsReversalEntry]
, [CreatedById]
, [CreatedTime]
, [UpdatedById]
, [UpdatedTime]
, [LegalEntityId])
VALUES (PostDate
, IsManualEntry
, IsReversalEntry
, @CreatedById
, @CreatedTime
, NULL
, NULL
, LegalEntityId)
OUTPUT	INSERTED.Id,
JournalParam.SourceId,
INSERTED.PostDate,
INSERTED.IsReversalEntry INTO #GLJournal;
--UPDATE #GLJournal SET SourceId = @WriteDownId
INSERT INTO [dbo].[GLJournalDetails] ([EntityId]
, [EntityType]
, [Amount_Amount]
, [Amount_Currency]
, [IsDebit]
, [GLAccountNumber]
, [Description]
, [SourceId]
, [CreatedById]
, [CreatedTime]
, [UpdatedById]
, [UpdatedTime]
, [GLAccountId]
, [GLTemplateDetailId]
, [MatchingGLTemplateDetailId]
, [LineofBusinessId]
, [ExportJobId]
, [GLJournalId]
, [IsActive]
,[InstrumentTypeGLAccountId])
SELECT
EntityId,
EntityType,
Amount,
Currency,
IsDebit,
GLAccountNumber,
Description,
@WriteDownId,
@CreatedById,
@CreatedTime,
NULL,
NULL,
GLAccountId,
GLTemplateDetailId,
MatchingGLTemplateDetailId,
LineofBusinessId,
NULL,
#GLJournal.GLJournalId,
IsActive,
InstrumentTypeGLAccountId
FROM @JournalDetailParam journalDetail
JOIN #GLJournal
ON journalDetail.SourceId = #GLJournal.SourceId
UPDATE WriteDowns
SET WriteDownGLJournalId = (SELECT TOP 1
GLJournalId
FROM #GLJournal)
WHERE Id = @WriteDownId
SET NOCOUNT OFF
END

GO
