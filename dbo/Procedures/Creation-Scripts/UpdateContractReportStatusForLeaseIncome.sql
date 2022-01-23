SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateContractReportStatusForLeaseIncome]
(
@MaturedContracts MaturedContracts READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@ReportStatus NVARCHAR(30)
) AS
BEGIN

SELECT c.Id INTO #ContractIds
FROM Contracts C
JOIN @MaturedContracts i ON C.Id = i.ContractId
WHERE C.ReportStatus <> @ReportStatus AND c.ChargeoffStatus = '_' 

UPDATE Contracts
SET ReportStatus = @ReportStatus
FROM Contracts c
JOIN @MaturedContracts i on c.Id = i.ContractId
WHERE c.ChargeOffStatus = '_'

INSERT INTO ContractReportStatusHistories (ReportStatus,  CreatedById, CreatedTime, ContractId)
SELECT @ReportStatus,@UpdatedById, @UpdatedTime, #ContractIds.Id
FROM #ContractIds 
END

GO
