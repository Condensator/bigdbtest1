SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP to fetch Nearest tax area for the location
CREATE PROCEDURE [dbo].[InsertVertexLocationTaxAreaDetail]
(
	@UALCode NVARCHAR(100),
	@JobStepInstanceId BIGINT
)
AS
BEGIN

	--DECLARE @UALCode NVARCHAR(100)=N'UAL',  @JobStepInstanceId BIGINT  = 120863 

	SET NOCOUNT ON

	CREATE TABLE #LocationsNearestTaxAreaEffectiveDate
	(
		LocationId BIGINT,
		AssetId BIGINT NULL,
		ReceivableDueDate DATE,
		TaxAreaEffectiveDate DATE
	)

	;WITH CTE_DistinctLocations AS
	(
		SELECT
			DISTINCT LocationId
		FROM SalesTaxReceivableDetailExtract
		WHERE 
			JobStepInstanceId = @JobStepInstanceId 
			AND InvalidErrorCode IS NULL
	)
	SELECT
		L.LocationId
		,LH.TaxAreaId
		,LH.TaxAreaEffectiveDate
		,LH.Id AS LocationTaxAreaHistoryId
	INTO #TaxAreaHistory
	FROM CTE_DistinctLocations L
	INNER JOIN LocationTaxAreaHistories LH 
		ON L.LocationId = LH.LocationId;

	INSERT INTO #LocationsNearestTaxAreaEffectiveDate
	(LocationId, AssetId, ReceivableDueDate, TaxAreaEffectiveDate)
	SELECT
		LD.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,MAX(LD.TaxAreaEffectiveDate) AS TaxAreaEffectiveDate
	FROM #TaxAreaHistory LD
	INNER JOIN SalesTaxReceivableDetailExtract ST 
		ON LD.LocationId = ST.LocationId 
		AND ST.JobStepInstanceId = @JobStepInstanceId
	WHERE	
		LD.TaxAreaEffectiveDate <= ST.ReceivableDueDate
	GROUP BY
		 LD.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate;

	INSERT INTO #LocationsNearestTaxAreaEffectiveDate
	SELECT
		LD.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,MIN(LD.TaxAreaEffectiveDate) AS TaxAreaEffectiveDate
	FROM #TaxAreaHistory LD
	INNER JOIN SalesTaxReceivableDetailExtract ST 
		ON LD.LocationId = ST.LocationId 
		AND ST.JobStepInstanceId = @JobStepInstanceId
	WHERE 
		LD.TaxAreaEffectiveDate > ST.ReceivableDueDate
	GROUP BY
		LD.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate;

	SELECT
		LocationId,
		AssetId,
		ReceivableDueDate,
		MIN(TaxAreaEffectiveDate) TaxAreaEffectiveDate
	INTO #DistinctLocations
	FROM #LocationsNearestTaxAreaEffectiveDate
	GROUP BY
		LocationId,
		AssetId,
		ReceivableDueDate

	SELECT
		LDE.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,LDH.TaxAreaEffectiveDate
		,MAX(LDH.LocationTaxAreaHistoryId) LocationTaxAreaHistoryId
	INTO #LocationTaxAreaDetails
	FROM #DistinctLocations AS LDE
	INNER JOIN SalesTaxReceivableDetailExtract ST 
		ON LDE.LocationId = ST.LocationId
		AND LDE.ReceivableDueDate = ST.ReceivableDueDate 
		AND ST.JobStepInstanceId = @JobStepInstanceId
		AND LDE.AssetId = ST.AssetId 
		AND ST.AssetId IS NOT NULL
	INNER JOIN #TaxAreaHistory LDH 
		ON LDE.LocationId = LDH.LocationId  
			AND LDH.TaxAreaEffectiveDate = LDE.TaxAreaEffectiveDate
	GROUP BY
		LDE.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,LDH.TaxAreaEffectiveDate;

	INSERT INTO #LocationTaxAreaDetails
	SELECT
		LDE.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,LDH.TaxAreaEffectiveDate
		,MAX(LDH.LocationTaxAreaHistoryId) LocationTaxAreaHistoryId
	FROM #DistinctLocations AS LDE
	INNER JOIN SalesTaxReceivableDetailExtract ST 
		ON LDE.LocationId = ST.LocationId
		AND LDE.ReceivableDueDate = ST.ReceivableDueDate 
		AND ST.JobStepInstanceId = @JobStepInstanceId
		AND ST.AssetId IS NULL
	INNER JOIN #TaxAreaHistory LDH 
		ON LDE.LocationId = LDH.LocationId  
			AND LDH.TaxAreaEffectiveDate = LDE.TaxAreaEffectiveDate
	GROUP BY
		LDE.LocationId
		,ST.AssetId
		,ST.ReceivableDueDate
		,LDH.TaxAreaEffectiveDate;

	INSERT INTO VertexLocationTaxAreaDetailExtract
	(
		[LocationId],
		[ReceivableDueDate], 
		[AssetId],  
		[TaxAreaId], 
		[TaxAreaEffectiveDate], 
		[JobStepInstanceId]
	)
	SELECT
		LD.LocationId
		,LD.ReceivableDueDate
		,LD.AssetId
		,TAX.TaxAreaId
		,LD.TaxAreaEffectiveDate
		,@JobStepInstanceId
	FROM #LocationTaxAreaDetails LD
	JOIN  #TaxAreaHistory TAX 
		ON LD.LocationTaxAreaHistoryId = TAX.LocationTaxAreaHistoryId;
	UPDATE ST SET InvalidErrorCode = CASE WHEN LTA.TaxAreaId IS NULL THEN @UALCode ELSE InvalidErrorCode END
	FROM SalesTaxReceivableDetailExtract ST
	INNER JOIN VertexLocationTaxAreaDetailExtract LTA 
		ON ST.LocationId = LTA.LocationId 
		AND ST.ReceivableDueDate = LTA.ReceivableDueDate 
		AND ST.JobStepInstanceId = @JobStepInstanceId 
		AND ST.JobStepInstanceId = LTA.JobStepInstanceId;

	DROP TABLE #TaxAreaHistory
	DROP TABLE #LocationsNearestTaxAreaEffectiveDate
	DROP TABLE #DistinctLocations
	DROP TABLE #LocationTaxAreaDetails
END

GO
