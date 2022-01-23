SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_OTPReclass]
AS
BEGIN

SELECT
	DISTINCT ot.AssetId INTO ##Asset_OTPReclass
FROM ##Asset_OverTerm ot
INNER JOIN AssetIncomeSchedules ais ON ot.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseFinances lf ON lis.LeaseFinanceId = lf.Id
INNER JOIN ##Asset_ContractInfo c ON lf.ContractId = c.ContractId
LEFT JOIN ##Asset_LeaseAmendmentInfo lam ON lam.ContractId = c.ContractId
WHERE lis.IsSchedule = 1 AND lis.IncomeType = 'OverTerm' 
AND ais.IsActive = 1 AND lis.IsLessorOwned = 1 AND lis.IsReclassOTP = 1
AND (lam.ContractId IS NULL OR (lam.ContractId IS NOT NULL AND lis.LeaseFinanceId >= lam.CurrentLeaseFinanceId))
GROUP BY ot.AssetId;

CREATE NONCLUSTERED INDEX IX_OTPReclass_AssetId ON ##Asset_OTPReclass(AssetId);

END

GO
