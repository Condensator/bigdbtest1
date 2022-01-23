SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateContractReportStatusForLoanIncome]
(
@JobStepInstanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@ReportStatus NVARCHAR(30)
) AS
BEGIN
SELECT lf.ContractId INTO #MaturedContracts
FROM LoanIncomeRecognitionJobExtracts le
JOIN LoanFinances lf ON le.LoanFinanceId = lf.Id
JOIN LoanIncomeSchedules li on lf.Id = li.LoanFinanceId
WHERE le.JobStepInstanceId = @JobStepInstanceId
AND li.IncomeDate = lf.MaturityDate
AND li.IsGlPosted = 1
AND li.IsAccounting = 1
AND li.AdjustmentEntry = 0


SELECT c.ID INTO #ContractIds FROM Contracts C
JOIN #MaturedContracts mc on c.Id = mc.ContractId
WHERE C.ReportStatus <> @ReportStatus 

UPDATE Contracts
SET ReportStatus = @ReportStatus
FROM Contracts c
JOIN #MaturedContracts mc on c.Id = mc.ContractId

INSERT INTO ContractReportStatusHistories (ContractId, ReportStatus, CreatedById, CreatedTime)
SELECT #ContractIds.Id, @ReportStatus, @UpdatedById, @UpdatedTime
FROM #ContractIds

IF OBJECT_ID('tempDB.#MaturedContracts') IS NOT NULL
DROP TABLE #MaturedContracts
END

GO
