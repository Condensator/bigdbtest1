SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateForLeaseIncomeRecognition]
(
 @PostDate    DATETIME,
 @UpdatedBy   BIGINT,
 @UpdatedTime DATETIME,
 @LeaseIncomeScheduleIds  LeaseIncomeScheduleIds ReadOnly,
 @ReclassIncomeScheduleIds  ReclassIncomeScheduleIds ReadOnly,
 @FloatRateIncomeIds  FloatRateIncomeIds ReadOnly,
 @BlendedIncomeIds  BlendedIncomeIds ReadOnly,
 @BlendedItemDetailIds  BlendedItemDetailIds ReadOnly,
 @LeasePaymentScheduleIds  LeasePaymentScheduleIds ReadOnly,
 @AssetvalueHistoryClearingIds AssetvalueHistoryClearingIds ReadOnly,
 @AssetvalueHistoryIds AssetvalueHistoryIds ReadOnly
)
AS
BEGIN

SELECT * INTO #LeaseIncomeScheduleIds FROM @LeaseIncomeScheduleIds
SELECT * INTO #ReclassIncomeScheduleIds FROM @ReclassIncomeScheduleIds
SELECT * INTO #FloatRateIncomeIds FROM @FloatRateIncomeIds
SELECT * INTO #BlendedIncomeIds FROM @BlendedIncomeIds
SELECT * INTO #BlendedItemDetailIds FROM @BlendedItemDetailIds
SELECT * INTO #LeasePaymentScheduleIds FROM @LeasePaymentScheduleIds
SELECT * INTO #AssetvalueHistoryClearingIds FROM @AssetvalueHistoryClearingIds
SELECT * INTO #AssetvalueHistoryIds FROM @AssetvalueHistoryIds

IF((SELECT COUNT(*) FROM #LeaseIncomeScheduleIds) > 0)
BEGIN
UPDATE LIS
SET IsGLPosted = 1,
PostDate = @PostDate,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules LIS
JOIN #LeaseIncomeScheduleIds LISI ON LIS.Id = LISI.Id
END

IF((SELECT COUNT(*) FROM #ReclassIncomeScheduleIds) > 0)
BEGIN
UPDATE LIS
SET IsReclassOTP = 1,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules LIS
JOIN #ReclassIncomeScheduleIds RISU ON LIS.Id = RISU.Id
END

IF((SELECT COUNT(*) FROM #FloatRateIncomeIds) > 0)
BEGIN
UPDATE LFRI
SET IsGLPosted = 1,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM LeaseFloatRateIncomes LFRI
JOIN #FloatRateIncomeIds FRI ON LFRI.Id = FRI.Id
END

IF((SELECT COUNT(*) FROM #BlendedIncomeIds) > 0)
BEGIN
UPDATE BIS
SET PostDate = @PostDate,
ReversalPostDate = NULL,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM BlendedIncomeSchedules BIS
JOIN #BlendedIncomeIds BI ON BIS.Id = BI.Id
END

IF((SELECT COUNT(*) FROM #BlendedItemDetailIds) > 0)
BEGIN
UPDATE BI
SET IsGLPosted = 1,
PostDate = @PostDate,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM BlendedItemDetails BI
JOIN #BlendedItemDetailIds BID ON BI.Id = BID.Id
END

IF((SELECT COUNT(*) FROM #LeasePaymentScheduleIds) > 0)
BEGIN
UPDATE LPS
SET IsActive = 0,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM LeasePaymentSchedules LPS
JOIN #LeasePaymentScheduleIds LP ON LPS.Id = LP.Id
END

IF((SELECT COUNT(*) FROM #AssetvalueHistoryClearingIds) > 0)
BEGIN
UPDATE AH
SET AH.NetValue_Amount = AHI.NetValue_Amount,
AH.NetValue_Currency = AHI.NetValue_Currency,
AH.IsCleared = AHI.IsCleared,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM AssetValueHistories AH
JOIN #AssetvalueHistoryClearingIds AHI ON AH.Id = AHI.Id
END

IF((SELECT COUNT(*) FROM #AssetvalueHistoryIds) > 0)
BEGIN
UPDATE AH
SET AH.GLJournalId = AHI.GLJournalId,
AH.PostDate = AHI.PostDate,
AH.ReversalGLJournalId = AHI.ReversalGLJournalId,
AH.ReversalPostDate = AHI.ReversalPostDate,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM AssetValueHistories AH
JOIN #AssetvalueHistoryIds AHI ON AH.Id = AHI.Id
END

DROP TABLE #LeaseIncomeScheduleIds 
DROP TABLE #ReclassIncomeScheduleIds
DROP TABLE #FloatRateIncomeIds
DROP TABLE #BlendedIncomeIds
DROP TABLE #BlendedItemDetailIds
DROP TABLE #LeasePaymentScheduleIds
DROP TABLE #AssetvalueHistoryClearingIds
DROP TABLE #AssetvalueHistoryIds

END

GO
