SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Asset_SyndicatedAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
	ea.AssetId
	,rft.ParticipatedPortion
	,rft.EffectiveDate
	,rft.RetainedPortion 
	,rft.ReceivableForTransferType  INTO ##Asset_SyndicatedAssets
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN
	##Asset_ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
	AND la.LeaseFinanceId = rft.SyndicationLeaseFinanceId AND la.IsActive = 1

CREATE NONCLUSTERED INDEX IX_SyndicatedAssets_AssetId ON ##Asset_SyndicatedAssets(AssetId);

END

GO
