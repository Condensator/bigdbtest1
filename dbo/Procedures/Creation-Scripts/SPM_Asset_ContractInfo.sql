SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_ContractInfo]
AS
BEGIN

SELECT 
	ea.AssetId
	,IIF((a.Status IN ('Leased','InvestorLeased')),c.SyndicationType,'NA') [SyndicationType]
	,c.Id AS [ContractId]
	,IIF(la.AssetId IS NOT NULL AND (a.Status IN ('Leased','InvestorLeased')),c.SequenceNumber,'NA') [SequenceNumber]
	,IIF(la.AssetId IS NOT NULL AND (a.Status IN ('Leased','InvestorLeased')),la.LeaseContractType,'NA') [ContractType] INTO ##Asset_ContractInfo
FROM ##Asset_EligibleAssets ea
INNER JOIN Assets a ON ea.AssetId = a.Id
LEFT JOIN ##Asset_LeaseAssetsInfo la ON ea.AssetId = la.AssetId
LEFT JOIN Contracts c ON la.LeaseContractId = c.Id;

CREATE NONCLUSTERED INDEX IX_ContractInfo_AssetId ON ##Asset_ContractInfo(AssetId);

END

GO
