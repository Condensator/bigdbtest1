SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_DateOffInventory]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

;WITH CTE AS
(
	SELECT
		AssetId
	FROM
	(SELECT 
		RANK() OVER(PARTITION BY EA.AssetId order by AH.Id DESC) AS RANK,EA.AssetId,AH.status
	FROM
		##Asset_EligibleAssets EA
	INNER JOIN
		AssetHistories AH ON AH.AssetId = EA.AssetId) T
	WHERE
		T.RANK=2 AND T.Status='Inventory'
)

SELECT
	T.AssetId,
	AsofDate    INTO ##Asset_DateOffInventory
FROM
(SELECT 
	RANK() OVER(PARTITION BY CTE.AssetId order by AH.id DESC) AS RANK,CTE.AssetId,AH.status,AH.AsOfDate
FROM
	CTE
JOIN
	AssetHistories AH ON CTE.AssetId = AH.AssetId) T
WHERE
	T.RANK=1

CREATE NONCLUSTERED INDEX IX_DateOffInventory_AssetId ON ##Asset_DateOffInventory(AssetId);

END

GO
