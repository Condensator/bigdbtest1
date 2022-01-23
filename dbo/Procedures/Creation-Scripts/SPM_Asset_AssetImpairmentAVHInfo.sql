SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_AssetImpairmentAVHInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	ea.AssetId  as AssetId
	,ea.AssetStatus
	,ea.IsLeaseComponent
	,avh.SourceModuleId
	,avh.GLJournalId
	,avh.ReversalGLJournalId
	,MAX(avh.Id) AS AVHId
	,MAX(avh.IncomeDate) AS AVHIncomeDate INTO ##Asset_AssetImpairmentAVHInfo
FROM 
	##Asset_EligibleAssets ea
INNER JOIN 
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
	AND avh.SourceModule = 'AssetImpairment' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
GROUP BY
	ea.AssetId,ea.AssetStatus,ea.IsLeaseComponent,avh.SourceModuleId,avh.GLJournalId,avh.ReversalGLJournalId;

CREATE NONCLUSTERED INDEX IX_AssetId ON ##Asset_AssetImpairmentAVHInfo(AssetId);

END

GO
