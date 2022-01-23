SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateSpecifiedleasingPropertyOfAnAsset]
(
@LeaseFinanceId BigInt = NULL
,@ExemptPropertyYes NVARCHAR(15) = NULL
,@ExemptPropertyNo  NVARCHAR(15) = NULL
,@ExemptPropertyNone  NVARCHAR(15) = NULL
,@SpecifiedLeasingPropertyLimit DECIMAL(18,2)
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @TermsInMonths  DECIMAL (4,1)
DECLARE @SumofLeasedAssetscosts DECIMAL(18,2)
SELECT Assets.Id AssetId, Assets.ExemptProperty,NBV_Amount
INTO #LeaseAssets
FROM LeaseAssets
JOIN Assets ON LeaseAssets.AssetId = Assets.Id
JOIN AssetTypes ON Assets.TypeId = AssetTypes.Id
WHERE LeaseAssets.LeaseFinanceId = @LeaseFinanceId AND LeaseAssets.IsActive = 1
SELECT @TermsInMonths = TermInMonths FROM LeaseFinanceDetails WHERE Id = @LeaseFinanceId
SELECT @SumofLeasedAssetscosts = SUM(#LeaseAssets.Nbv_Amount) FROM #LeaseAssets
WHERE ExemptProperty != @ExemptPropertyYes
UPDATE Assets SET SpecifiedLeasingProperty = @ExemptPropertyNone
FROM Assets
JOIN #LeaseAssets ON Assets.Id = #LeaseAssets.AssetId
WHERE #LeaseAssets.ExemptProperty IS NULL
UPDATE Assets SET SpecifiedLeasingProperty =
CASE WHEN Assets.ExemptProperty=@ExemptPropertyNone THEN @ExemptPropertyNone
WHEN Assets.ExemptProperty=@ExemptPropertyYes THEN @ExemptPropertyNo
WHEN Assets.ExemptProperty=@ExemptPropertyNo AND @TermsInMonths > 12 AND @SumofLeasedAssetscosts > @SpecifiedLeasingPropertyLimit
THEN @ExemptPropertyYes ELSE @ExemptPropertyNo END
FROM Assets
JOIN #LeaseAssets ON Assets.Id = #LeaseAssets.AssetId
DROP TABLE #LeaseAssets
END

GO
