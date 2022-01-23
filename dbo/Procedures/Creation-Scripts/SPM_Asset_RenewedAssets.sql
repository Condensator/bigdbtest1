SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Asset_RenewedAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
	ea.AssetId
	,lam.AmendmentDate  INTO ##Asset_RenewedAssets
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
	AND la.IsActive = 1
INNER JOIN
	##Asset_LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId

CREATE NONCLUSTERED INDEX IX_RenewedAssets_AssetId ON ##Asset_RenewedAssets(AssetId);

END

GO
