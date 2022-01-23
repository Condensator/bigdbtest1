SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Asset_AVHClearedTillDate]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
	ea.AssetId
	,MAX(avh.IncomeDate) AVHClearedTillDate
	,MAX(avh.Id) AVHClearedId   INTO ##Asset_AVHClearedTillDate
FROM
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE
	avh.IsCleared = 1
	AND avh.IsAccounted = 1
GROUP BY
	ea.AssetId;

CREATE NONCLUSTERED INDEX IX_AVHClearedTillDate_AssetId ON ##Asset_AVHClearedTillDate(AssetId);

END

GO
