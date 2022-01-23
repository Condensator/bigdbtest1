SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Asset_BookDepId]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @IsSku BIT = 0;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @IsSku = 1
END;

BEGIN
SELECT
	t.AssetId
	,t.IsLeaseComponent
	,CASE WHEN t.MaxLastAmortRunDate IS NOT NULL THEN t.MaxBookDepId ELSE t.MinBookDepId END BookDepreciationId  INTO ##Asset_BookDepId
FROM (
	SELECT
		bd.AssetId
		,ea.IsLeaseComponent
		,Min(bd.Id) MinBookDepId
		,Max(bd.Id) MaxBookDepId
		,Max(bd.LastAmortRunDate) as MaxLastAmortRunDate
	FROM ##Asset_EligibleAssets ea
	INNER JOIN 
		BookDepreciations bd ON bd.AssetId = ea.AssetId
		AND ea.IsSKU = 0
	GROUP BY bd.AssetId,ea.IsLeaseComponent) AS t
END

If @IsSku = 1
BEGIN

INSERT INTO ##Asset_BookDepId
SELECT
	t.AssetId
	,t.IsLeaseComponent
	,CASE WHEN t.MaxLastAmortRunDate IS NOT NULL THEN t.MaxBookDepId ELSE t.MinBookDepId END BookDepreciationId
FROM (
	SELECT
		bd.AssetId
		,bd.IsLeaseComponent
		,Min(bd.Id) MinBookDepId
		,Max(bd.Id) MaxBookDepId
		,Max(bd.LastAmortRunDate) MaxLastAmortRunDate
	FROM 
		##Asset_EligibleAssets ea
	INNER JOIN
		BookDepreciations bd ON bd.AssetId = ea.AssetId
		AND ea.IsSKU = 1
	GROUP BY
		bd.AssetId,bd.IsLeaseComponent) AS t
END

CREATE NONCLUSTERED INDEX IX_Id ON ##Asset_BookDepId(AssetId);

END

GO
