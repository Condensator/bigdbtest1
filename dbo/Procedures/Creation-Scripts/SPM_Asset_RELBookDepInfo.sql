SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_RELBookDepInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
	 bdi.AssetId
	,MAX(bd.RemainingLifeInMonths) AS RemainingLifeInMonths INTO ##Asset_RELBookDepInfo
FROM 
	##Asset_BookDepId bdi
INNER JOIN
	BookDepreciations bd ON bdi.BookDepreciationId = bd.Id
	AND bd.TerminatedDate IS NULL AND bd.IsActive = 1 AND bd.ContractId IS NULL
GROUP BY bdi.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON ##Asset_RELBookDepInfo(AssetId);

END

GO
