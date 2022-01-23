SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateReceiptDeferredTaxToReprocessForRecovery]
(
@ContractsInRecovery ContractsInRecovery READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ContractsInRecovery(
ContractId BIGINT,
RecoveryDate DATE
)

INSERT INTO #ContractsInRecovery(ContractId, RecoveryDate)
SELECT ContractId, RecoveryDate FROM @ContractsInRecovery

CREATE TABLE #DeferredTaxesToUpdate(
DeferredTaxId BIGINT,
ContractId BIGINT,
RecoveryDate DATE
)

CREATE NONCLUSTERED INDEX IX_DeferredContractUpdate ON #DeferredTaxesToUpdate(ContractId, RecoveryDate);

;WITH DeferredTaxToUpdate_CTE AS (
SELECT
Contracts.ContractId, Contracts.RecoveryDate, MIN(DeferredTaxes.Date) MinDeferredTaxDate
FROM #ContractsInRecovery Contracts
JOIN DeferredTaxes ON  Contracts.ContractId = DeferredTaxes.ContractId AND DeferredTaxes.IsScheduled=1
AND DeferredTaxes.Date > Contracts.RecoveryDate
GROUP BY Contracts.ContractId, Contracts.RecoveryDate
)
INSERT INTO #DeferredTaxesToUpdate(ContractId, DeferredTaxId, RecoveryDate)
SELECT DeferredTaxes.ContractId, DeferredTaxes.Id, DeferredTaxToUpdate_CTE.RecoveryDate
FROM DeferredTaxToUpdate_CTE
JOIN DeferredTaxes ON DeferredTaxes.ContractId = DeferredTaxToUpdate_CTE.ContractId 
AND DeferredTaxes.[Date] = MinDeferredTaxDate

IF NOT EXISTS(SELECT TOP 1 1 FROM #DeferredTaxesToUpdate)
BEGIN
	RETURN;
END

CREATE TABLE #DeferedTaxInReProcess(
ContractId BIGINT,
[Date] DATE
)

INSERT INTO #DeferedTaxInReProcess(ContractId, Date)
SELECT Contracts.ContractId, DeferredTaxes.[Date]
FROM #ContractsInRecovery Contracts
JOIN DeferredTaxes ON Contracts.ContractId = DeferredTaxes.ContractId AND DeferredTaxes.IsScheduled=1
AND DeferredTaxes.IsReprocess = 1

CREATE TABLE #Output (
ContractId BIGINT,
DeferredTaxId BIGINT
)

UPDATE DeferredTaxes SET IsReprocess = 1, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
OUTPUT INSERTED.ContractId, INSERTED.Id DeferredTaxId
INTO #Output
FROM DeferredTaxes 
JOIN #DeferredTaxesToUpdate ON DeferredTaxes.Id = #DeferredTaxesToUpdate.DeferredTaxId
JOIN #DeferedTaxInReProcess ON #DeferredTaxesToUpdate.ContractId = #DeferedTaxInReProcess.ContractId 
WHERE #DeferedTaxInReProcess.Date > #DeferredTaxesToUpdate.RecoveryDate 

UPDATE DeferredTaxes SET IsReprocess = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM #Output AS DeferredTaxToRevert
JOIN DeferredTaxes ON DeferredTaxToRevert.ContractId = DeferredTaxes.ContractId AND DeferredTaxes.IsReprocess = 1
AND DeferredTaxes.Id <> DeferredTaxToRevert.DeferredTaxId

DROP TABLE #DeferedTaxInReProcess
DROP TABLE #DeferredTaxesToUpdate

END

GO
