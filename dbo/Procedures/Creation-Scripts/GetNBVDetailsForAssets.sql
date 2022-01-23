SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNBVDetailsForAssets]
(
@TakeBeginNBV BIT,
@InventoryBookDepreciationType NVARCHAR(40),
@FixedTermDepreciationType NVARCHAR(40),
@AssetValueAdjustmentType NVARCHAR(40),
@AssetImpairmentType NVARCHAR(40),
@OTPDepreciationType NVARCHAR(40),
@ResidualRecaptureType NVARCHAR(40),
@NBVImpairmentType NVARCHAR(40),
@IsFromNBVImpairment BIT,
@IsFromImportAssets BIT,
@AssetIncomeDateInfo AssetIncomeDateCollection READONLY

)
AS

BEGIN
	SET NOCOUNT ON
	SELECT AssetId AS AssetId, AsOfDate AS IncomeDate
	INTO #AssetIds
	FROM @AssetIncomeDateInfo

	CREATE INDEX IX_AssetId On #AssetIds (AssetId) INCLUDE (IncomeDate)

	SELECT
		PIA.Id PIAId,
		PIA.PayableInvoiceId,
		A.AssetId
	INTO #PIAInfo
	FROM #AssetIds A
	JOIN PayableInvoiceAssets PIA ON A.AssetId = PIA.AssetId
	WHERE PIA.IsActive = 1

	SELECT
		PIAId,
		PIOC.Id PIOCId,
		A.AssetId
	INTO #PIOCDInfo
	FROM #PIAInfo A
	JOIN PayableInvoiceOtherCosts PIOC ON A.PayableInvoiceId= PIOC.PayableInvoiceId AND PIOC.IsPrepaidUpfrontTax = 1
	WHERE PIOC.IsActive = 1 AND PIOC.AllocationMethod IN ('AssetCount','AssetCost','Specific')

	SELECT 
			A.AssetId,
			SUM(PIOCD.Amount_Amount) PrepaidUpfrontTaxAmount
	INTO #PrepaidUpfrontTaxInfo
	FROM #PIOCDInfo A
	JOIN PayableInvoiceOtherCostDetails PIOCD ON A.PIAId = PIOCD.PayableInvoiceAssetId AND A.PIOCId = PIOCD.PayableInvoiceOtherCostId
	WHERE PIOCD.IsActive = 1
	GROUP BY A.AssetId;

	SELECT Id, assetIds.IncomeDate INTO #Ids		
	FROM AssetValueHistories
	JOIN #AssetIds assetIds ON assetIds.AssetId = AssetValueHistories.AssetId
	AND AssetValueHistories.IsSchedule=1 

	SELECT #Ids.Id AS Id,
	AssetValueHistories.IncomeDate AS IncomeDate, 
	AssetValueHistories.AssetId AS AssetId,
	AssetValueHistories.IsLessorOwned AS IsLessorOwned,
	AssetValueHistories.IsLeaseComponent AS IsLeaseComponent,
	AssetValueHistories.SourceModule AS SourceModule,
	AssetValueHistories.Cost_Amount AS Cost_Amount,
	AssetValueHistories.NetValue_Amount AS NetValue_Amount,
	AssetValueHistories.BeginBookValue_Amount AS BeginBookValue_Amount,
	AssetValueHistories.EndBookValue_Amount AS EndBookValue_Amount,
	AssetValueHistories.Value_Amount AS Value_Amount,
	AssetValueHistories.IsSchedule AS IsSchedule
	INTO #AssetValueHistoryFiltered
	FROM AssetValueHistories
	JOIN #Ids ON #Ids.Id = AssetValueHistories.Id
	WHERE #Ids.IncomeDate IS NULL
	
	INSERT INTO #AssetValueHistoryFiltered
	SELECT #Ids.Id AS Id,
	AssetValueHistories.IncomeDate AS IncomeDate, 
	AssetValueHistories.AssetId AS AssetId,
	AssetValueHistories.IsLessorOwned AS IsLessorOwned,
	AssetValueHistories.IsLeaseComponent AS IsLeaseComponent,
	AssetValueHistories.SourceModule AS SourceModule,
	AssetValueHistories.Cost_Amount AS Cost_Amount,
	AssetValueHistories.NetValue_Amount AS NetValue_Amount,
	AssetValueHistories.BeginBookValue_Amount AS BeginBookValue_Amount,
	AssetValueHistories.EndBookValue_Amount AS EndBookValue_Amount,
	AssetValueHistories.Value_Amount AS Value_Amount,
	AssetValueHistories.IsSchedule AS IsSchedule
	FROM AssetValueHistories
	JOIN #Ids ON #Ids.Id = AssetValueHistories.Id
	WHERE AssetValueHistories.IncomeDate <= #Ids.IncomeDate

	SELECT MAX(assetValueHistoryFiltered.IncomeDate) AS IncomeDate,assetValueHistoryFiltered.AssetId ,assetValueHistoryFiltered.IsLessorOwned, assetValueHistoryFiltered.IsLeaseComponent
	INTO #AssetValueHistoryTemp 
	FROM #AssetValueHistoryFiltered assetValueHistoryFiltered
	WHERE assetValueHistoryFiltered.IsSchedule=1 
	GROUP BY assetValueHistoryFiltered.AssetId,assetValueHistoryFiltered.IsLessorOwned, assetValueHistoryFiltered.IsLeaseComponent
	 
	SELECT MAX(assetValueHistoryFiltered.Id) AS Id
	INTO #AssetValueHistoryIds
	FROM #AssetValueHistoryFiltered assetValueHistoryFiltered 
	JOIN #AssetValueHistoryTemp on #AssetValueHistoryTemp.AssetId = assetValueHistoryFiltered.AssetId 
	AND #AssetValueHistoryTemp.IsLessorOwned = assetValueHistoryFiltered.IsLessorOwned and #AssetValueHistoryTemp.IsLeaseComponent = assetValueHistoryFiltered.IsLeaseComponent
	AND #AssetValueHistoryTemp.IncomeDate = assetValueHistoryFiltered.IncomeDate
	GROUP BY assetValueHistoryFiltered.AssetId , assetValueHistoryFiltered.IsLessorOwned, assetValueHistoryFiltered.IsLeaseComponent

	SELECT 
		AVH.AssetId
		,(CASE WHEN AVH.SourceModule IN (@InventoryBookDepreciationType,@FixedTermDepreciationType,@AssetValueAdjustmentType,@AssetImpairmentType,@OTPDepreciationType,@ResidualRecaptureType) THEN DATEADD(DAY,1,AVH.IncomeDate) ELSE AVH.IncomeDate END) AS AsOfDate
		,AVH.Cost_Amount AS Cost
		,AVH.NetValue_Amount AS NetValue
		,(CASE WHEN (@TakeBeginNBV = 1 AND (@IsFromNBVImpairment = 0 OR AVH.SourceModule <> @NBVImpairmentType)) THEN AVH.BeginBookValue_Amount ELSE AVH.EndBookValue_Amount END) AS NBV
		,CAST(0 AS BIT) IsPrepaidUpfrontTax
		,CAST(0.00 AS DECIMAL(16,2)) PrepaidUpfrontTax
		,AVH.IsLessorOwned
		,AVH.IsLeaseComponent
	INTO #AssetNBVInfo
	FROM #AssetValueHistoryFiltered AVH
	JOIN #AssetValueHistoryIds ON AVH.Id = #AssetValueHistoryIds.Id;

	UPDATE #AssetNBVInfo 
			SET #AssetNBVInfo.IsPrepaidUpfrontTax = 1,
					#AssetNBVInfo.PrepaidUpfrontTax = PUFT.PrepaidUpfrontTaxAmount
	FROM #AssetNBVInfo AV
	JOIN #PrepaidUpfrontTaxInfo PUFT ON AV.AssetId = PUFT.AssetId

	IF(@IsFromImportAssets = 1)
	BEGIN
		;WITH CTE_AVH
		AS (SELECT ROW_NUMBER() OVER (PARTITION BY assetValueHistoryFiltered.AssetId,assetValueHistoryFiltered.IsLeaseComponent ORDER BY assetValueHistoryFiltered.IncomeDate,assetValueHistoryFiltered.Id) RowNumber,
		assetValueHistoryFiltered.AssetId,
		assetValueHistoryFiltered.Value_Amount,
		assetValueHistoryFiltered.IsLeaseComponent   
		FROM #AssetNBVInfo 
		JOIN #AssetValueHistoryFiltered assetValueHistoryFiltered ON #AssetNBVInfo.AssetId = assetValueHistoryFiltered.AssetId AND #AssetNBVInfo.IsLeaseComponent = assetValueHistoryFiltered.IsLeaseComponent AND assetValueHistoryFiltered.IsSchedule = 1 --AND AssetValueHistories.IsLessorOwned = 1
		LEFT JOIN (SELECT #AssetNBVInfo.AssetId 
									FROM 
									#AssetNBVInfo
									JOIN LeaseAssets ON #AssetNBVInfo.AssetId = LeaseAssets.AssetId
									JOIN PayoffAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId AND PayoffAssets.IsActive=1
									JOIN Payoffs ON PayoffAssets.PayoffId = Payoffs.Id AND Payoffs.Status = 'Activated') 
							AS TransferAssets ON #AssetNBVInfo.AssetId = TransferAssets.AssetId
		WHERE assetValueHistoryFiltered.SourceModule = 'PayableInvoice'
		AND TransferAssets.AssetId IS NULL)

		UPDATE #AssetNBVInfo
		SET NBV = NBV - SpecificCostAdj.Value_Amount,
				NetValue = NBV - SpecificCostAdj.Value_Amount
		FROM #AssetNBVInfo
		JOIN (SELECT AssetId,IsLeaseComponent, SUM(Value_Amount) Value_Amount FROM CTE_AVH WHERE RowNumber <> 1 GROUP BY AssetId,IsLeaseComponent) 
		AS SpecificCostAdj ON #AssetNBVInfo.AssetId = SpecificCostAdj.AssetId and #AssetNBVInfo.IsLeaseComponent = SpecificCostAdj.IsLeaseComponent
	END

	SELECT 
		AssetId
		,AsofDate
		,Cost
		,NetValue
		,NBV
		,NULL As LeaseAsset
		,IsPrepaidUpfrontTax
		,PrepaidUpfrontTax
		,IsLessorOwned
		,IsLeaseComponent
	FROM #AssetNBVInfo

	DROP TABLE #PrepaidUpfrontTaxInfo
	DROP TABLE #AssetValueHistoryTemp
	DROP TABLE #AssetValueHistoryIds
	DROP TABLE #AssetNBVInfo
	DROP TABLE #AssetIds 
       
END

GO
