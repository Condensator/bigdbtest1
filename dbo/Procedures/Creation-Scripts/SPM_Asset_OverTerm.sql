SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_OverTerm]
AS
BEGIN

SELECT 
	Distinct ea.AssetId  INTO ##Asset_OverTerm
FROM ##Asset_EligibleAssets ea
INNER JOIN AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseFinances lf ON lis.LeaseFinanceId = lf.Id
INNER JOIN ##Asset_ContractInfo c ON lf.ContractId = c.ContractId
WHERE lis.IsSchedule = 1 AND lis.IncomeType = 'OverTerm' AND ais.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_OverTerm_AssetId ON ##Asset_OverTerm(AssetId);

END

GO
