SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE   PROC [dbo].[SPM_Asset_ChargeOffMaxCleared]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT
	 ea.AssetId
	,avh.IncomeDate AS ChargeOffMaxClearedIncomeDate	INTO ##Asset_ChargeOffMaxCleared
FROM 
	##Asset_EligibleAssets ea
INNER JOIN
	AssetValueHistories avh ON ea.AssetId = avh.AssetId
	AND	avh.SourceModule = 'ChargeOff';

CREATE NONCLUSTERED INDEX IX_ChargeOffMaxCleared_AssetId ON ##Asset_ChargeOffMaxCleared(AssetId);

END

GO
