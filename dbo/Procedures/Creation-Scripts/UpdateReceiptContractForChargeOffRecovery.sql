SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceiptContractForChargeOffRecovery](
@ChargeOffStatusValues_Recovery NVARCHAR(40),
@ContractIds IdCollection READONLY,
@ChargeOffRecovery_ReportStatus NVARCHAR(40),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
) AS
BEGIN
SELECT * INTO #ContractIds FROM @ContractIds

SELECT c.Id INTO #ContractIdToUpdates
FROM Contracts C
JOIN #ContractIds ON C.Id = #ContractIds.Id
WHERE C.ReportStatus <> @ChargeOffRecovery_ReportStatus 

UPDATE Contracts SET ChargeOffStatus = @ChargeOffStatusValues_Recovery,
ReportStatus = @ChargeOffRecovery_ReportStatus,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM #ContractIds AS ContractIds
JOIN Contracts ON ContractIds.Id = Contracts.Id

INSERT INTO ContractReportStatusHistories (ReportStatus,  CreatedById, CreatedTime, ContractId)
SELECT @ChargeOffRecovery_ReportStatus,@CreatedById, @CreatedTime, #ContractIdToUpdates.Id
FROM #ContractIdToUpdates 

DROP TABLE #ContractIds
END

GO
