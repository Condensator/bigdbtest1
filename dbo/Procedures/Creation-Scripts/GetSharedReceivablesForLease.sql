SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetSharedReceivablesForLease]
(
@EntityId  BIGINT,
@EntityType NVARCHAR(2),
@IsAdvance BIT,
@ReceivableIncomeType NVARCHAR(16),
@InterimRentAdjustmentEffectiveDate DATETIME = NULL
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #SharedReceivableDetailIds
(
DueDate DATETIME,
PercentageToShare DECIMAL
)
CREATE TABLE #AdjustmentReceivableIds
(
ReceivableId BIGINT,
)
INSERT INTO #AdjustmentReceivableIds
SELECT Receivabledetails.ReceivableId FROM
ReceivableDetails Receivabledetails
JOIN Receivables on ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableDetails AdjustmentReceivables on Receivabledetails.Id = AdjustmentReceivables.AdjustmentBasisReceivableDetailId
WHERE  ReceivableDetails.IsActive =1
AND AdjustmentReceivables.IsActive =1
AND Receivables.EntityId = @EntityId
AND Receivables.IsActive =1
AND Receivables.IncomeType = @ReceivableIncomeType
INSERT INTO #SharedReceivableDetailIds
SELECT DISTINCT Receivables.DueDate AS DueDate,RentSharingDetails.Percentage AS PercentageToShare
FROM
Receivables
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN RentSharingDetails ON Receivables.Id = RentSharingDetails.ReceivableId
LEFT JOIN #AdjustmentReceivableIds ON Receivables.Id = #AdjustmentReceivableIds.ReceivableId
WHERE Receivables.IsActive =1
AND Receivables.EntityId = @EntityId
AND Receivables.IncomeType = @ReceivableIncomeType
AND ReceivableDetails.AdjustmentBasisReceivableDetailId IS NULL
AND #AdjustmentReceivableIds.ReceivableId IS NULL
AND (@InterimRentAdjustmentEffectiveDate IS NULL OR ((@IsAdvance = 1 AND Receivables.DueDate < @InterimRentAdjustmentEffectiveDate) OR( @IsAdvance = 0 AND Receivables.DueDate <= @InterimRentAdjustmentEffectiveDate)))
SELECT * FROM  #SharedReceivableDetailIds
DROP TABLE #SharedReceivableDetailIds
DROP TABLE #AdjustmentReceivableIds
SET NOCOUNT OFF;
END

GO
