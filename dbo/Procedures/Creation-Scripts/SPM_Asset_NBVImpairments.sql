SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Asset_NBVImpairments]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	ea.AssetId,
	SUM(avh.Value_Amount) AS NBVImpairment  INTO  ##Asset_NBVImpairments
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN
	LeaseAssets ai ON ai.AssetId = ea.AssetId
INNER JOIN 
	LeaseFinances lf ON Lf.Id = ai.LeaseFinanceId and lf.iscurrent=1
WHERE
	avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
	AND avh.SourceModule IN ('NBVImpairments')
	AND ai.IsFailedSaleLeaseback = 0
	AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
GROUP BY 
	ea.AssetId

CREATE NONCLUSTERED INDEX IX_NBVImpairments_AssetId ON ##Asset_NBVImpairments(AssetId);

END

GO
