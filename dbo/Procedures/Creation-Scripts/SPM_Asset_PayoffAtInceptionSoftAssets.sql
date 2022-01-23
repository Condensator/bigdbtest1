SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_PayoffAtInceptionSoftAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
    DISTINCT ea.AssetId  INTO ##Asset_PayoffAtInceptionSoftAssets
FROM 
    ##Asset_EligibleAssets ea
INNER JOIN 
    ##Asset_CapitalizedSoftAssetInfo coa ON ea.AssetId = coa.AssetId
INNER JOIN
    LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
    PayoffAssets po ON po.LeaseAssetId = la.Id
INNER JOIN
    Payoffs p ON po.PayoffId = p.Id
WHERE
    ea.AssetStatus = 'Scrap'
    AND p.PayoffAtInception = 1 

CREATE NONCLUSTERED INDEX IX_PayoffAtInceptionSoftAssets_AssetId ON ##Asset_PayoffAtInceptionSoftAssets(AssetId);

 

END

GO
