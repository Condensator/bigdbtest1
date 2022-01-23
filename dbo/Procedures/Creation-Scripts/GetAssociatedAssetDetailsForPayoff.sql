SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAssociatedAssetDetailsForPayoff]
(
@RealAssetId LeaseAssetsDetail READONLY,
@PayableInvoiceStatusCompleted NVARCHAR(10),
@LeaseFinanceId BIGINT,
@DepositType NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #AssociatedAssetInfo
(
LeaseAssetId BIGINT,
AssociatedLeaseAssetId BIGINT,
IsSoftAsset BIT
)
SELECT LeaseAssetId = Id INTO #SelectedLeaseAssets FROM @RealAssetId
INSERT INTO #AssociatedAssetInfo
SELECT
LeaseAssetId = LA.Id,
AssociatedLeaseAssetId = LA1.Id,
IsSoftAsset = CAST(0 AS BIT)
FROM
LeaseAssets LA
JOIN
#SelectedLeaseAssets SA ON LA.Id = SA.LeaseAssetId
JOIN
Assets A ON LA.AssetId  = A.Id
JOIN
PayableInvoiceAssets PA ON A.Id = PA.AssetId
JOIN
PayableInvoiceDepositAssets PAD ON PA.Id = PAD.DepositAssetId
JOIN
PayableInvoiceDepositTakeDownAssets PADA ON PAD.Id = PADA.PayableInvoiceDepositAssetId
JOIN
PayableInvoiceAssets PA1 ON PADA.TakeDownAssetId = PA1.Id
JOIN
LeaseAssets LA1 ON PA1.AssetId = LA1.AssetId
JOIN
PayableInvoices PIV ON PA1.PayableInvoiceId =PIV.Id
WHERE
LA.LeaseFinanceId = @LeaseFinanceId
AND
LA1.LeaseFinanceId = @LeaseFinanceId
AND
A.FinancialType = @DepositType
AND PIV.Status = @PayableInvoiceStatusCompleted
AND LA.IsActive = 1
AND PAD.IsActive = 1
AND PA.IsActive = 1
AND PADA.IsActive = 1
AND PA.IsActive =1
AND LA1.IsActive=1
AND PA1.IsActive=1
INSERT INTO #AssociatedAssetInfo
SELECT
LeaseAssetId = SA.LeaseAssetId,
AssociatedAssetId = SoftAsset.Id,
IsSoftAsset = CAST(1 AS BIT)
FROM
#SelectedLeaseAssets SA
JOIN
LeaseAssets LA ON SA.LeaseAssetId = LA.Id
JOIN
LeaseAssets SoftAsset ON LA.Id = SoftAsset.CapitalizedForId
WHERE
LA.LeaseFinanceId = @LeaseFinanceId
AND
SoftAsset.LeaseFinanceId = @LeaseFinanceId
AND
LA.IsActive=1
AND
SoftAsset.IsActive =1
SELECT
LeaseAssetId,
AssociatedLeaseAssetId,
IsSoftAsset
FROM
#AssociatedAssetInfo AI
DROP TABLE
#SelectedLeaseAssets,
#AssociatedAssetInfo
END

GO
