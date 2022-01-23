SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateReceiptChunkerForPosting]    
(    
@ReceiptBatchStatus_New	NVARCHAR(40),
@JobStepInstanceId		BIGINT,
@BatchSize				BIGINT,
@CreatedById			BIGINT,
@CreatedTime			DATETIMEOFFSET,
@ReceiptSourceModule	NVARCHAR(21) = '_',
@HasChunkingFailed		BIT OUT
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #InsertedDataChunker
(
Id				BIGINT,
BatchNumber		BIGINT,
)
CREATE TABLE #InsertedDataChunkerDetail
(
ReceiptId		BIGINT
)    
SELECT    
RARD.ReceiptId    
,RARD.ContractId    
,RARD.IsWritedownContract    
,RARD.IsChargeoffContract    
,CASE WHEN RLRD.LateFeeReceivableId IS NOT NULL THEN 1 ELSE 0 END AS IsLateFeeReceipt    
,RARD.InvoiceId    
,RARD.ReceivableId    
,RDE.PayDownId    
INTO #ReceiptDataChunkerDetails    
FROM ReceiptReceivableDetails_Extract RARD    
JOIN Receipts_Extract RDE ON RARD.ReceiptId = RDE.ReceiptId AND RDE.JobStepInstanceId = @JobStepInstanceId    
LEFT JOIN ReceiptLateFeeReversalDetails_Extract RLRD ON RARD.ReceiptId = RLRD.ReceiptId    
WHERE RARD.JobStepInstanceId = @JobStepInstanceId    
AND RDE.IsValid = 1   
GROUP BY    
RARD.ReceiptId    
,RARD.ContractId    
,RARD.IsWritedownContract    
,RARD.IsChargeoffContract    
,CASE WHEN RLRD.LateFeeReceivableId IS NOT NULL THEN 1 ELSE 0 END    
,RARD.InvoiceId    
,RARD.ReceivableId    
,RDE.PayDownId    
;    
INSERT INTO #ReceiptDataChunkerDetails    
SELECT    
RDE.ReceiptId    
,RDE.ContractId    
,0    
,0    
,0    
,null    
,null    
,RDE.PayDownId    
FROM Receipts_Extract RDE     
LEFT JOIN ReceiptReceivableDetails_Extract RARD ON RARD.ReceiptId = RDE.ReceiptId AND RDE.JobStepInstanceId = @JobStepInstanceId    
WHERE RDE.JobStepInstanceId = @JobStepInstanceId    
AND RDE.IsValid = 1    
AND RARD.Id IS NULL    
AND RDE.PayDownId IS NOT NULL    
GROUP BY    
RDE.ReceiptId    
,RDE.ContractId    
,RDE.PayDownId    
;    
SELECT *, @JobStepInstanceId AS JobStepInstanceId INTO #ReceiptGroupDetails FROM #ReceiptDataChunkerDetails    
WHERE IsWritedownContract = 1 OR IsChargeoffContract = 1    
OR IsLateFeeReceipt = 1 OR PayDownId IS NOT NULL    
ORDER BY IsWritedownContract DESC, IsChargeoffContract DESC, IsLateFeeReceipt DESC,    
ContractId ASC,PayDownId ASC, InvoiceId ASC, ReceivableId ASC    
;    
INSERT INTO #ReceiptGroupDetails    
SELECT *, @JobStepInstanceId AS JobStepInstanceId FROM #ReceiptDataChunkerDetails    
WHERE IsWritedownContract = 0 AND IsChargeoffContract = 0    
AND IsLateFeeReceipt = 0 AND PayDownId IS NULL    
ORDER BY ContractId ASC, InvoiceId ASC, ReceivableId ASC    
;    
SELECT    
ContractId, @JobStepInstanceId JobStepInstanceId, COUNT(DISTINCT ReceiptId) ReceiptIdCount    
INTO #ContractGroupDetails    
FROM #ReceiptGroupDetails    
WHERE ContractId IS NOT NULL    
GROUP BY IsWritedownContract, IsLateFeeReceipt, IsChargeoffContract, ContractId, PayDownId    
HAVING COUNT(*) > 1    
;    
DELETE FROM #ReceiptGroupDetails    
WHERE ContractId IN (SELECT ContractId  FROM #ContractGroupDetails)    
;    
SELECT    
InvoiceId, @JobStepInstanceId JobStepInstanceId , COUNT(DISTINCT ReceiptId) ReceiptIdCount    
INTO #InvoiceGroupDetails    
FROM #ReceiptGroupDetails    
WHERE InvoiceId IS NOT NULL    
GROUP BY IsWritedownContract, IsLateFeeReceipt, IsChargeoffContract, InvoiceId    
HAVING COUNT(*) > 1    
;    
DELETE FROM #ReceiptGroupDetails    
WHERE InvoiceId IN (SELECT InvoiceId  FROM #InvoiceGroupDetails)    
;    
SELECT    
ReceivableId, @JobStepInstanceId JobStepInstanceId, COUNT(DISTINCT ReceiptId) ReceiptIdCount    
INTO #ReceivableGroupDetails    
FROM #ReceiptGroupDetails    
WHERE ReceivableId IS NOT NULL    
GROUP BY IsWritedownContract, IsLateFeeReceipt, IsChargeoffContract, ReceivableId    
HAVING COUNT(*) > 1    
;    
DELETE FROM #ReceiptGroupDetails    
WHERE ReceivableId IN (SELECT ReceivableId  FROM #ReceivableGroupDetails)    
;    
SELECT    
ROW_NUMBER() OVER(ORDER BY JobStepInstanceId) AS RowNumber, CAST(1 AS BIGINT) BatchNumber, *    
INTO #ReceiptTable FROM    
(    
SELECT ContractId, 0 AS InvoiceId, 0 AS ReceivableId, JobStepInstanceId, ReceiptIdCount FROM #ContractGroupDetails    
UNION    
SELECT 0 AS ContractId, InvoiceId, 0 AS ReceivableId, JobStepInstanceId, ReceiptIdCount FROM #InvoiceGroupDetails    
UNION    
SELECT 0 AS ContractId, 0 AS InvoiceId, ReceivableId, JobStepInstanceId, ReceiptIdCount FROM #ReceivableGroupDetails    
UNION    
SELECT ContractId, InvoiceId, ReceivableId, JobStepInstanceId, 1 AS ReceiptIdCount FROM #ReceiptGroupDetails    
) AS TMP    
;    
DECLARE @ReceiptIdCount BIGINT    
DECLARE @PreviousReceiptIdCount BIGINT = 0    
DECLARE @ReceiptIdCountSum BIGINT = 0    
DECLARE @ReceiptIdCountTemp BIGINT = 0    
DECLARE @BatchNumber BIGINT = 1    
DECLARE RowCount_Cursor CURSOR FOR    
SELECT ReceiptIdCount FROM #ReceiptTable    
WHERE ReceiptIdCount < @BatchSize    
OPEN RowCount_Cursor    
FETCH NEXT FROM RowCount_Cursor INTO @ReceiptIdCount    
WHILE @@FETCH_STATUS = 0    
BEGIN    
SET @ReceiptIdCountTemp = @ReceiptIdCount + @PreviousReceiptIdCount    
IF(@ReceiptIdCountTemp > @BatchSize)    
BEGIN    
SET @BatchNumber = @BatchNumber + 1;    
END    
IF(@PreviousReceiptIdCount = 0 OR @ReceiptIdCountTemp > @BatchSize)    
BEGIN    
SET @ReceiptIdCountSum = @ReceiptIdCount    
END    
ELSE    
BEGIN    
SET @ReceiptIdCountSum = @ReceiptIdCountTemp    
END    
UPDATE #ReceiptTable    
SET   BatchNumber = @BatchNumber    
WHERE  CURRENT OF RowCount_Cursor;    
SET @PreviousReceiptIdCount = @ReceiptIdCountSum    
FETCH NEXT FROM RowCount_Cursor INTO @ReceiptIdCount    
END    
CLOSE RowCount_Cursor    
DEALLOCATE RowCount_Cursor    
MERGE INTO ReceiptChunkerForPosting_Extract X    
USING (SELECT BatchNumber FROM #ReceiptTable GROUP BY BatchNumber) AS Batch ON 1 = 0    
WHEN NOT MATCHED BY TARGET THEN    
INSERT (PostingBatchStatus, PrePostingBatchStatus, JobStepInstanceId, CreatedById, CreatedTime, SourceModule)    
VALUES (@ReceiptBatchStatus_New, @ReceiptBatchStatus_New, @JobStepInstanceId, @CreatedById, @CreatedTime, @ReceiptSourceModule)    
OUTPUT INSERTED.ID, Batch.BatchNumber    
INTO #InsertedDataChunker (Id, BatchNumber)    
;    
INSERT INTO ReceiptChunkerForPostingDetail_Extract (ReceiptId, JobStepInstanceId, ReceiptChunkerForPosting_ExtractId, CreatedById, CreatedTime)    
OUTPUT INSERTED.ReceiptId INTO #InsertedDataChunkerDetail (ReceiptId)    
SELECT DISTINCT    
RD.ReceiptId, @JobStepInstanceId, MIN(IDC.Id), @CreatedById, @CreatedTime    
FROM  #InsertedDataChunker IDC    
JOIN #ReceiptTable RT ON IDC.BatchNumber = RT.BatchNumber    
JOIN #ReceiptDataChunkerDetails RD ON RT.ContractId = RD.ContractId    
GROUP BY RD.ReceiptId    
;    
DELETE R FROM #ReceiptDataChunkerDetails R    
JOIN #InsertedDataChunkerDetail ID ON R.ReceiptId = ID.ReceiptId    
;    
INSERT INTO ReceiptChunkerForPostingDetail_Extract (ReceiptId, JobStepInstanceId, ReceiptChunkerForPosting_ExtractId, CreatedById, CreatedTime)    
OUTPUT INSERTED.ReceiptId INTO #InsertedDataChunkerDetail (ReceiptId)    
SELECT DISTINCT    
RD.ReceiptId, @JobStepInstanceId, MAX(IDC.Id), @CreatedById, @CreatedTime    
FROM  #InsertedDataChunker IDC    
JOIN #ReceiptTable RT ON IDC.BatchNumber = RT.BatchNumber    
JOIN #ReceiptDataChunkerDetails RD ON RT.InvoiceId = RD.InvoiceId    
GROUP BY RD.ReceiptId    
;    
DELETE R FROM #ReceiptDataChunkerDetails R    
JOIN #InsertedDataChunkerDetail ID ON R.ReceiptId = ID.ReceiptId    
;    
INSERT INTO ReceiptChunkerForPostingDetail_Extract (ReceiptId, JobStepInstanceId, ReceiptChunkerForPosting_ExtractId, CreatedById, CreatedTime)    
SELECT DISTINCT    
RD.ReceiptId, @JobStepInstanceId, MAX(IDC.Id), @CreatedById, @CreatedTime    
FROM  #InsertedDataChunker IDC    
JOIN #ReceiptTable RT ON IDC.BatchNumber = RT.BatchNumber    
JOIN #ReceiptDataChunkerDetails RD ON RT.ReceivableId = RD.ReceivableId    
GROUP BY RD.ReceiptId    
;    
CREATE TABLE #InsertedUnappliedReceiptChunk    
(    
Id BIGINT,    
BatchNumber BIGINT   
);    
SELECT    
R.ReceiptId, ((ROW_NUMBER() OVER(ORDER BY R.ReceiptId)) - 1) / @BatchSize + 1 AS BatchNumber    
INTO #UnappliedReceipts    
FROM Receipts_Extract R    
LEFT JOIN ReceiptReceivableDetails_Extract RARD ON R.ReceiptId = RARD.ReceiptId AND R.JobStepInstanceId = RARD.JobStepInstanceId    
WHERE R.JobStepInstanceId = @JobStepInstanceId    
AND R.IsValid = 1    
AND RARD.Id IS NULL    
AND R.PayDownId IS NULL    
;    
MERGE INTO ReceiptChunkerForPosting_Extract X    
USING (SELECT BatchNumber FROM #UnappliedReceipts GROUP BY BatchNumber) AS Batch ON 1 = 0    
WHEN NOT MATCHED BY TARGET THEN    
INSERT (PostingBatchStatus, PrePostingBatchStatus, JobStepInstanceId, CreatedById, CreatedTime, SourceModule)    
VALUES (@ReceiptBatchStatus_New, @ReceiptBatchStatus_New, @JobStepInstanceId, @CreatedById, @CreatedTime, @ReceiptSourceModule)    
OUTPUT INSERTED.ID, Batch.BatchNumber    
INTO #InsertedUnappliedReceiptChunk (Id, BatchNumber)    
;    
INSERT INTO ReceiptChunkerForPostingDetail_Extract (ReceiptId, JobStepInstanceId, ReceiptChunkerForPosting_ExtractId, CreatedById, CreatedTime)    
SELECT    
R.ReceiptId, @JobStepInstanceId, DC.Id, @CreatedById, @CreatedTime    
FROM #UnappliedReceipts R    
JOIN #InsertedUnappliedReceiptChunk DC ON R.BatchNumber = DC.BatchNumber    
;    
--Output Operations    
SET @HasChunkingFailed=0    
DECLARE @CountOfReceipts BIGINT    
DECLARE @CountOfReceiptChunkDetails BIGINT    
SET @CountOfReceipts = (SELECT Count(1) FROM Receipts_Extract WHERE JobStepInstanceId=@JobStepInstanceId AND IsValid = 1)    
SET @CountOfReceiptChunkDetails = (SELECT Count(1) FROM ReceiptChunkerForPostingDetail_Extract WHERE JobStepInstanceId=@JobStepInstanceId)    
IF @CountOfReceipts!=@CountOfReceiptChunkDetails    
BEGIN    
SET @HasChunkingFailed=1
Update Receipts_Extract set IsValid = 0 where JobStepInstanceId=@JobStepInstanceId;
END    
IF EXISTS(SELECT 1 FROM ReceiptChunkerForPostingDetail_Extract WHERE JobStepInstanceId=@JobStepInstanceId GROUP BY ReceiptId HAVING COUNT(1)>1)    
BEGIN    
SET @HasChunkingFailed=1
Update Receipts_Extract set IsValid = 0 where JobStepInstanceId=@JobStepInstanceId;
END    
END

GO
