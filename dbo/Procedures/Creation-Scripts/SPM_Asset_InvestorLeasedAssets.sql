SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Asset_InvestorLeasedAssets]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	A.Id as AssetId INTO ##Asset_InvestorLeasedAssets
FROM
	Assets a
INNER JOIN
	LeaseAssets la ON la.AssetId = a.Id
INNER JOIN
	LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN 
	##Asset_ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
	AND rft.IsFromContract = 1

CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_InvestorLeasedAssets(AssetId);

END

GO
