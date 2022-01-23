SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_LeaseAssetsInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	ea.AssetId
	,lf.ContractId [LeaseContractId]
	,lfd.LeaseContractType [LeaseContractType]
	,lfd.CommencementDate
	,lf.Id [LeaseFinanceId]
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
	,ea.AssetStatus
	,CASE WHEN ea.AssetStatus IN ('Leased','InvestorLeased') AND ea.HoldingStatus = 'HFI'
	THEN DATEDIFF(Month,ea.AcquisitionDate,lfd.MaturityDate)
	ELSE 0
	END [RemainingEconomicLife]  INTO ##Asset_LeaseAssetsInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN 
	LeaseAssets la ON ea.AssetId = la.AssetId
	AND la.IsActive = 1
INNER JOIN 
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
	AND lf.IsCurrent = 1
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id

CREATE NONCLUSTERED INDEX IX_Id ON ##Asset_LeaseAssetsInfo(AssetId);

END

GO
