SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateContractReportStatus]
(
@JobStepInstanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@ReportStatus NVARCHAR(30)
) AS    
BEGIN
Select C.Id INTO #ContractId
FROM Contracts c
Join LeaseExtensionJobExtracts  e on c.Id = e.ContractId
WHERE e.JobStepInstanceId = @JobStepInstanceId
AND C.reportStatus <> @ReportStatus

UPDATE Contracts
SET ReportStatus = @ReportStatus
FROM Contracts c
Join LeaseExtensionJobExtracts  e on c.Id = e.ContractId
WHERE e.JobStepInstanceId = @JobStepInstanceId

INSERT INTO ContractReportStatusHistories (ContractId, ReportStatus, CreatedById, CreatedTime)
SELECT Id, @ReportStatus, @UpdatedById, @UpdatedTime
FROM #ContractId
END

GO
