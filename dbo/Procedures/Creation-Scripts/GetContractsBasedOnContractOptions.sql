SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetContractsBasedOnContractOptions]
(
@InputContractIds ContractIdsForAutoPayoff READONLY,
@ParameterDetailId BIGINT NULL
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @MaturityMonitorResponse NVARCHAR(25)
DECLARE @MaturityMonitorStatus NVARCHAR(10)
SET @MaturityMonitorResponse = (SELECT [Value] FROM #AutopayoffEnums WHERE [Name] = 'MaturityMonitorResponse')
SET @MaturityMonitorStatus = (SELECT [Value] FROM #AutopayoffEnums WHERE [Name] = 'MaturityMonitorStatus')
SELECT
[Values] = CPD.[Value]
INTO #ParameterValues
FROM
AutoPayoffTemplateCollectionParameterDetails CPD
JOIN AutoPayoffTemplateParameterDetails PD ON PD.Id = CPD.AutoPayoffTemplateParameterDetailId
WHERE PD.ID = @ParameterDetailId
AND CPD.IsActive = 1
AND PD.IsActive = 1
SELECT DISTINCT ContractId INTO #ContractsWithNotifications
FROM
(SELECT
ContractId = IC.Id,
ROW_NUMBER() OVER (PARTITION BY MMLN.ContractOptionSelected ORDER BY MMLN.NoticeReceivedDate DESC, MMLN.UpdatedTime DESC) RowNumber,
MMLN.Status,
MMLN.Response
FROM @InputContractIds IC
JOIN MaturityMonitors ON IC.Id = MaturityMonitors.ContractId
INNER JOIN MaturityMonitorLesseeNotifications MMLN ON MaturityMonitors.Id = MMLN.MaturityMonitorId AND MMLN.IsActive = 1
WHERE MMLN.ContractOptionSelected IN (SELECT [Values] FROM #ParameterValues)
) AS ContractOptions
WHERE
RowNumber = 1 AND
Status = @MaturityMonitorStatus AND
Response = @MaturityMonitorResponse
SELECT IC.Id ContractId
FROM @InputContractIds IC
INNER JOIN MaturityMonitors
ON IC.Id = MaturityMonitors.ContractId
LEFT JOIN MaturityMonitorLesseeNotifications
ON MaturityMonitors.Id = MaturityMonitorLesseeNotifications.MaturityMonitorId AND
MaturityMonitorLesseeNotifications.IsActive = 1
LEFT JOIN MaturityMonitorRenewalDetails
ON MaturityMonitors.Id  = MaturityMonitorRenewalDetails.MaturityMonitorId AND
MaturityMonitorRenewalDetails.IsActive = 1
WHERE IC.Id NOT IN (SELECT ContractId FROM #ContractsWithNotifications) AND
MaturityMonitorLesseeNotifications.MaturityMonitorId IS NULL AND
MaturityMonitorRenewalDetails.MaturityMonitorId IS NULL
UNION
SELECT
ContractId
FROM
#ContractsWithNotifications
SET NOCOUNT OFF;
END

GO
