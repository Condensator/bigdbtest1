SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PerformSpecificCostAdjustmentFromLease] 
(
@PayableInvoiceOtherCostIds NVarChar(max), 
@SourceModule NVarChar(25), 
@CreatedById BIGINT, 
@CreatedTime DATETIMEOFFSET) 

AS BEGIN 

CREATE TABLE #InsertedAssetValueHistories
(
	AssetId BIGINT NOT NULL,
	AssetValueHistoryId BIGINT NOT NULL,
	IsLeaseComponent BIT NOT NULL
)

SELECT PayableInvoiceOtherCosts.Id [PayableInvoiceOtherCostId] INTO #LeaseCostAdjustedSpecificcost
FROM PayableInvoiceOtherCosts
JOIN Assets ON PayableInvoiceOtherCosts.AssetId =Assets.Id
JOIN AssetValueHistories ON Assets.Id=AssetValueHistories.AssetId
WHERE PayableInvoiceOtherCosts.Id in (SELECT Id FROM ConvertCSVToBigIntTable(@PayableInvoiceOtherCostIds,','))
  AND AssetValueHistories.SourceModule=@SourceModule
  AND AssetValueHistories.SourceModuleId=PayableInvoiceOtherCosts.PayableInvoiceId
  AND AssetValueHistories.IsSchedule=1
  AND AssetValueHistories.IsAccounted=1
  AND AssetValueHistories.IsLessorOwned = 1

SELECT PayableInvoiceOtherCosts.Id PayableInvoiceOtherCostId,
        PayableInvoiceOtherCosts.AssetId,
        PayableInvoiceOtherCosts.PayableInvoiceId,
        payableinvoices.InvoiceDate,
        (PayableInvoiceOtherCosts.Amount_Amount*payableinvoices.InitialExchangeRate) Amount,
		PayableInvoices.InitialExchangeRate,
        payableinvoices.PostDate,
        CurrencyCodes.ISO,
		PayableInvoiceOtherCosts.AssignOtherCostAtSKULevel INTO #SpecificCostToAdjust
FROM PayableInvoiceOtherCosts
JOIN payableinvoices ON PayableInvoiceOtherCosts.PayableInvoiceId=payableinvoices.Id
JOIN Currencies ON payableinvoices.ContractCurrencyId=Currencies.Id
JOIN CurrencyCodes ON Currencies.CurrencyCodeId=CurrencyCodes.Id
WHERE PayableInvoiceOtherCosts.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@PayableInvoiceOtherCostIds,','))
AND PayableInvoiceOtherCosts.Id NOT IN
(SELECT PayableInvoiceOtherCostId FROM #LeaseCostAdjustedSpecificcost) 

SELECT AssetValueHistories.Id,
AssetValueHistories.AssetId,
        AssetValueHistories.Value_Amount ValueAmount,
        AssetValueHistories.NetValue_Amount NetValueAmount ,
        AssetValueHistories.EndBookValue_Amount EndBookValueAmount,
        AssetValueHistories.Cost_Amount CostAmount,
        AssetValueHistories.BeginBookValue_Amount BeginBookValueAmount,
        ROW_NUMBER() OVER (PARTITION BY AssetValueHistories.AssetId ORDER BY id DESC) AS rowNumber,
		AssetValueHistories.IsLeaseComponent  INTO #LatestAssetValueHistory
FROM AssetValueHistories
JOIN #SpecificCostToAdjust ON AssetValueHistories.AssetId=#SpecificCostToAdjust.AssetId
WHERE AssetValueHistories.IsAccounted=1 AND AssetValueHistories.IsSchedule=1 AND AssetValueHistories.IsLessorOwned = 1

INSERT INTO AssetValueHistories
(
SourceModule,
SourceModuleId,
FromDate, 
ToDate, 
IncomeDate, 
Value_Amount, 
Value_Currency, 
NetValue_Amount,
NetValue_Currency, 
Cost_Amount, 
Cost_Currency, 
BeginBookValue_Amount,
BeginBookValue_Currency, 
EndBookValue_Amount,
EndBookValue_Currency, 
IsAccounted,
IsSchedule, 
IsCleared,
PostDate, 
AssetId,
CreatedById, 
CreatedTime, 
GLJournalId, 
AdjustmentEntry,
IsLessorOwned,
IsLeaseComponent)
OUTPUT INSERTED.AssetId,INSERTED.Id,INSERTED.IsLeaseComponent INTO #InsertedAssetValueHistories
SELECT @SourceModule,
       PayableInvoiceId,
       NULL,
       NULL,
       #SpecificCostToAdjust.InvoiceDate,
       #SpecificCostToAdjust.Amount,
       #SpecificCostToAdjust.ISO,
       #LatestAssetValueHistory.NetValueAmount+#SpecificCostToAdjust.Amount,
       #SpecificCostToAdjust.ISO,
       #LatestAssetValueHistory.CostAmount+#SpecificCostToAdjust.Amount,
       #SpecificCostToAdjust.ISO,
       #LatestAssetValueHistory.EndBookValueAmount,
       #SpecificCostToAdjust.ISO,
       #LatestAssetValueHistory.EndBookValueAmount+#SpecificCostToAdjust.Amount,
       #SpecificCostToAdjust.ISO,
       1,
       1,
       1,
       #SpecificCostToAdjust.PostDate,
       #LatestAssetValueHistory.AssetId,
       @CreatedById,
       @CreatedTime,
       NULL,
       0,
	   1,
	   #LatestAssetValueHistory.IsLeaseComponent
FROM #LatestAssetValueHistory
JOIN #SpecificCostToAdjust ON #LatestAssetValueHistory.AssetId = #SpecificCostToAdjust.AssetId
WHERE #LatestAssetValueHistory.rowNumber=1

SELECT	AssetSKUs.Id AssetSKUId,
		AssetSKUs.AssetId,
		AssetSKUs.IsActive,
		CASE WHEN PayableInvoiceOtherCostSKUDetails.Id IS NULL THEN SKUValueProportions.Value_Amount
			ELSE PayableInvoiceOtherCostSKUDetails.OtherCost_Amount * #SpecificCostToAdjust.InitialExchangeRate
		END  SKUSpecificCostAdjustment,
		#SpecificCostToAdjust.ISO,
	   AssetSKUs.IsLeaseComponent
INTO #SKUSpecificCostToAdjust FROM Assets 
JOIN AssetSKUs ON Assets.Id = AssetSKUs.AssetId
JOIN PayableInvoiceAssetSKUs ON AssetSKUs.Id = PayableInvoiceAssetSKUs.AssetSKUId
JOIN SKUValueProportions ON AssetSKUs.Id = SKUValueProportions.AssetSKUId
LEFT JOIN PayableInvoiceOtherCostSKUDetails ON PayableInvoiceAssetSKUs.Id = PayableInvoiceOtherCostSKUDetails.PayableInvoiceAssetSKUId
LEFT JOIN #SpecificCostToAdjust ON PayableInvoiceOtherCostSKUDetails.PayableInvoiceOtherCostId = #SpecificCostToAdjust.PayableInvoiceOtherCostId
LEFT JOIN #LatestAssetValueHistory ON SKUValueProportions.AssetValueHistoryId = #LatestAssetValueHistory.Id
WHERE #SpecificCostToAdjust.AssignOtherCostAtSKULevel = 1

INSERT INTO [dbo].[SKUValueProportions]
	 ([Value_Amount]
	 ,[Value_Currency]
	 ,[CreatedById]
	 ,[CreatedTime]
	 ,[AssetSKUId]
	 ,[IsActive]
	 ,[AssetValueHistoryId]
	 )  
	SELECT 
	 #SKUSpecificCostToAdjust.SKUSpecificCostAdjustment
	,#SKUSpecificCostToAdjust.ISO
	,@CreatedById
	,@CreatedTime
	,#SKUSpecificCostToAdjust.AssetSKUId
	,#SKUSpecificCostToAdjust.IsActive 	
	,#InsertedAssetValueHistories.AssetValueHistoryId
	FROM #SKUSpecificCostToAdjust
	JOIN #InsertedAssetValueHistories ON #SKUSpecificCostToAdjust.AssetId = #InsertedAssetValueHistories.AssetId AND #SKUSpecificCostToAdjust.IsLeaseComponent = #InsertedAssetValueHistories.IsLeaseComponent


UPDATE PayableInvoiceOtherCosts
SET IsLeaseCostAdjusted=1
FROM PayableInvoiceOtherCosts
JOIN #SpecificCostToAdjust ON PayableInvoiceOtherCosts.Id=#SpecificCostToAdjust.PayableInvoiceOtherCostId

END


GO
