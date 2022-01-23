SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetOldCPUScheduleInfoForRestructure]
(
@CPUFinanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
/*CPU Schedule Info*/
SELECT
CS.Id AS 'ScheduleId',
CS.ScheduleNumber,
CBS.NumberofPayments,
CBS.IsRegularPaymentStream,
CBS.BaseAmount_Amount AS BaseAmount,
CBS.BaseUnit,
CASE WHEN CO.CPUOverageStructureId IS NOT NULL THEN COUNT(CO.Id) ELSE 0 END AS 'OverageTierCount',
CASE WHEN CA.CPUScheduleId IS NOT NULL THEN COUNT(CA.Id) ELSE 0 END AS 'ServiceOnlyAssetCount'
FROM CPUSchedules CS
JOIN CPUBaseStructures CBS on CS.Id = CBS.Id
LEFT JOIN CPUOverageTiers CO ON CS.Id = CO.CPUOverageStructureId AND CO.IsActive = 1
LEFT JOIN CPUAssets CA ON CS.Id = CA.CPUScheduleId AND CA.IsActive = 1 AND CA.IsServiceOnly = 1 AND CA.ContractId IS NULL
WHERE CS.IsActive = 1 AND CS.CPUFinanceId = @CPUFinanceId
GROUP BY CS.Id , CS.ScheduleNumber ,CBS.IsRegularPaymentStream,  CBS.BaseAmount_Amount,
CBS.BaseUnit,CBS.DistributionBasis, CBS.NumberofPayments , CO.CPUOverageStructureId , CA.CPUScheduleId
SET NOCOUNT OFF;
END

GO
