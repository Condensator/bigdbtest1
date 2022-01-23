SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReprocessInDeferredTaxes]
(
@RecoveredContractIds RecoveredContractIdCollection READONLY,
@ReceivedDate DATE,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
RecoveredContractId.ContractId,
DeferredTaxes.Date
INTO #DeferredTaxInfo
FROM
@RecoveredContractIds as RecoveredContractId
JOIN DeferredTaxes ON RecoveredContractId.ContractId = DeferredTaxes.ContractId AND IsScheduled = 1 AND IsReprocess = 1
UPDATE DeferredTaxes SET IsReprocess = 1,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
FROM
DeferredTaxes DT
JOIN Contracts ON DT.ContractId = Contracts.Id AND IsScheduled = 1
JOIN @RecoveredContractIds RC ON Contracts.Id = RC.ContractId
LEFT JOIN #DeferredTaxInfo ON DT.ContractId = #DeferredTaxInfo.ContractId
WHERE
(#DeferredTaxInfo.Date IS NULL OR #DeferredTaxInfo.Date > @ReceivedDate)
AND DT.Date = (SELECT MIN(DATE) FROM DeferredTaxes WHERE ContractId = Contracts.Id AND Date > @ReceivedDate AND IsScheduled = 1)
-- Reset Reprocess Flag for Records Post
UPDATE DeferredTaxes SET IsReprocess = 0,UpdatedById = @CreatedById , UpdatedTime = @CreatedTime
FROM
DeferredTaxes
JOIN Contracts ON DeferredTaxes.ContractId = Contracts.Id AND IsScheduled = 1 AND IsReprocess = 1
JOIN @RecoveredContractIds RC ON Contracts.Id = RC.ContractId
AND Date > (SELECT MIN(Date) FROM DeferredTaxes WHERE ContractId = Contracts.Id AND IsScheduled = 1 AND IsReprocess = 1)
END

GO
