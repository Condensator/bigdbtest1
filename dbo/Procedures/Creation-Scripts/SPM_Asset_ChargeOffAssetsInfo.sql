SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_ChargeOffAssetsInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	ea.AssetId as AssetId
	,co.ChargeOffDate
	,co.ContractId
	,co.Id AS ChargeOffId INTO ##Asset_ChargeOffAssetsInfo
FROM
	##Asset_EligibleAssets ea
INNER JOIN 
	ChargeOffAssetDetails coa ON coa.AssetId = ea.AssetId
	AND coa.IsActive = 1
INNER JOIN
	ChargeOffs co ON co.Id = coa.ChargeOffId
	AND co.IsActive = 1 AND co.Status = 'Approved'
	AND co.IsRecovery = 0 AND co.ReceiptId IS NULL

CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_ChargeOffAssetsInfo(AssetId);

END

GO
