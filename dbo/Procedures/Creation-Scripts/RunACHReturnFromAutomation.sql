SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[RunACHReturnFromAutomation]
(
@JobStepInstanceId BIGINT,
@ScenarioName NVARCHAR(MAX),
@ReversalReasonCode NVARCHAR(60)='R01',
@ReceiptClassification NVARCHAR(MAX) = NULL,
@ReceiptAmount NVARCHAR(MAX)=NULL,
@ReceivedDate NVARCHAR(MAX) = NULL
)
AS
BEGIN

DECLARE @GUID UniqueIdentifier= NEWID();

CREATE TABLE #Temp
(
ACHRunId BIGINT,
ACHRunFileId BIGINT,
IsProcessed BIT,
ReversalReasonCode NVARCHAR(10),
ReceiptAmount DECIMAL(16,2),
TraceNumber NVARCHAR(50)
)
DECLARE @SQL NVARCHAR(MAX);

 SET @SQL =
'INSERT INTO #Temp
SELECT R.Id ACHRunId,F.Id ACHRunFileId,0 IsProcessed , '''+@ReversalReasonCode+''' ReversalReasonCode,SUM(RR.ReceiptAmount_Amount) ReceiptAmount,RD.TraceNumber
FROM ACHRuns R
JOIN ACHRunFiles F ON R.Id = F.ACHRunId
JOIN ACHRunDetails RD ON F.Id = RD.ACHRunFileId
JOIN Receipts RR ON RR.Id = RD.EntityId
WHERE R.JobStepInstanceId = '+CAST(@JobStepInstanceId AS NVARCHAR)+'
RECEIPT_CLASSIFICATION
Receipt_Amount1
RECEIVEDDATE1
AND RD.IsPending = 0
GROUP BY R.Id,F.Id,RD.TraceNumber

 INSERT INTO #Temp
SELECT R.Id ACHRunId,F.Id ACHRunFileId,0 IsProcessed , '''+@ReversalReasonCode+''' ReversalReasonCode,SUM(RR.ReceiptAmount),RD.TraceNumber
FROM ACHRuns R
JOIN ACHRunFiles F ON R.Id = F.ACHRunId
JOIN ACHRunDetails RD ON F.Id = RD.ACHRunFileId
JOIN ACHReceipts RR ON RR.Id = RD.EntityId
WHERE R.JobStepInstanceId = ' + CAST(@JobStepInstanceId AS NVARCHAR)+'
AND RD.IsPending = 1
RECEIPT_CLASSIFICATION
Receipt_Amount2
RECEIVEDDATE2
GROUP BY R.Id,F.Id,RD.TraceNumber'

IF @ReceiptAmount IS NOT NULL
BEGIN
SET @SQL=REPLACE( @SQL, 'Receipt_Amount1', 'AND RR.ReceiptAmount_Amount in'+ @ReceiptAmount)
SET @SQL=REPLACE( @SQL, 'Receipt_Amount2', 'AND RR.ReceiptAmount in'+ @ReceiptAmount)
END
ELSE
BEGIN
SET @SQL=REPLACE( @SQL, 'Receipt_Amount2', '')
SET @SQL=REPLACE( @SQL, 'Receipt_Amount1', '')
END

IF @ReceivedDate IS NOT NULL
BEGIN
SET @SQL=REPLACE( @SQL, 'RECEIVEDDATE1', ' AND RR.ReceivedDate in '+@ReceivedDate)
SET @SQL=REPLACE( @SQL, 'RECEIVEDDATE2', ' AND RR.SettlementDate in '+@ReceivedDate)
END
ELSE
BEGIN
SET @SQL=REPLACE( @SQL, 'RECEIVEDDATE1', '')
SET @SQL=REPLACE( @SQL, 'RECEIVEDDATE2', '')
END

 IF @ReceiptClassification IS NOT NULL
BEGIN
SET @SQL=REPLACE( @SQL, 'RECEIPT_CLASSIFICATION', ' AND RR.ReceiptClassification in '+@ReceiptClassification)
END
ELSE
BEGIN
SET @SQL=REPLACE( @SQL, 'RECEIPT_CLASSIFICATION', '')
END

 EXEC sp_executesql @sql;

 WHILE EXISTS(SELECT Top 1 ACHRunId FROM #Temp WHERE IsProcessed = 0)
BEGIN

 DECLARE @ACHFileDetails ACHFileDetails
DECLARE @ACHRunFileId BIGINT = (SELECT TOP 1 ACHRunFileId FROM #Temp WHERE IsProcessed = 0)
DECLARE @CurrentDate DATETIMEOFFSET = GETDATE()

 INSERT INTO @ACHFileDetails
SELECT 1,1,ReversalReasonCode,ReceiptAmount,TraceNumber
FROM #Temp WHERE ACHRunFileId = @ACHRunFileId;
EXECUTE [dbo].[GetACHReturnDetails]
1
,@CurrentDate
,1
,@ScenarioName
,@ACHRunFileId
,@ACHFileDetails
,'DSL'
,'Receipt'
,'Inactive'
,'Reversed'
,'Posted'
,'ACH'
,'WebOneTimeACH'
,'PAP'
,'WebOneTimePAP'
,'Approved'
,@GUID

 Update #Temp SET IsProcessed = 1 WHERE ACHRunFileId = @ACHRunFileId
DELETE FROM @ACHFileDetails
END

 SELECT @GUID;
END

GO
