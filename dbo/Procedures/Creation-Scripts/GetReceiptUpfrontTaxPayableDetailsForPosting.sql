SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptUpfrontTaxPayableDetailsForPosting]
(
@JobStepInstanceId BIGINT,
@ReceiptIds IdCollection READONLY
)
AS
BEGIN
SELECT ReceiptId,
ContractId,
AssetId,
LeaseAssetSalesTaxResposibillity,
SalesTaxResposibillityFromHistories,
EffectiveTillDate,
VendorId,
PayableCodeId,
LeaseAssetVendorRemitToId,
VendorRemitToIdFromHistories
FROM @ReceiptIds R
JOIN ReceiptUpfrontTaxDetails_Extract RUT ON R.Id = RUT.ReceiptId AND RUT.JobStepInstanceId = @JobStepInstanceId
END

GO
