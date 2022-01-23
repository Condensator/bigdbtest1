SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_DateInInventory]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	T.AssetId,
	AsofDate    INTO ##Asset_DateInInventory
FROM
	(SELECT 
		RANK() OVER(PARTITION BY EA.AssetId order by AH.Id DESC) AS RANK,EA.AssetId,AH.status,AH.AsofDate
	FROM
		##Asset_EligibleAssets EA
	INNER JOIN
		AssetHistories AH ON AH.AssetId = EA.AssetId) T
	WHERE
		T.RANK=1 AND T.Status='Inventory'

CREATE NONCLUSTERED INDEX IX_DateInInventory_AssetId ON ##Asset_DateInInventory(AssetId);

END

GO
