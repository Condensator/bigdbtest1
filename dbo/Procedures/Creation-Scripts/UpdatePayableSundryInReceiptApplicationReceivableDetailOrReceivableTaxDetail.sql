SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePayableSundryInReceiptApplicationReceivableDetailOrReceivableTaxDetail]
(
@PayableSundryDetail PayableSundryDetail READONLY,
@UpdatedTime DateTimeOffset,
@UpdatedById BIGINT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--UPDATE LA
--SET LA.UpfrontTaxSundryId = Info.SundryId,
--	LA.UpdatedTime= @UpdatedTime,
--	LA.UpdatedById = @UpdatedById
--FROM LeaseAssets LA
--JOIN @PayableSundryDetail Info ON LA.Id = Info.LeaseAssetId AND LA.AssetId = Info.AssetId AND LA.IsActive = 1
UPDATE RTD
SET RTD.UpfrontTaxSundryId = Info.SundryId,
RTD.UpdatedTime= @UpdatedTime,
RTD.UpdatedById = @UpdatedById
FROM ReceivableTaxDetails RTD
JOIN @PayableSundryDetail Info ON RTD.ReceivableDetailId = Info.ReceivableDetailId AND RTD.AssetId = Info.AssetId AND RTD.IsActive = 1 AND Info.ReceiptId IS NULL
UPDATE RARD
SET RARD.UpfrontTaxSundryId = Info.SundryId,
RARD.UpdatedTime= @UpdatedTime,
RARD.UpdatedById = @UpdatedById
FROM ReceiptApplicationReceivableDetails RARD
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
JOIN Receipts  R ON R.Id = RA.ReceiptId
JOIN @PayableSundryDetail Info ON RARD.ReceivableDetailId = Info.ReceivableDetailId AND RARD.IsActive = 1 AND Info.ReceiptId IS NOT NULL AND Info.ReceiptId = R.Id
END

GO
