SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLateFeeNonRentalSplittedContractBasedReceivables]
(
@receivableAssetAmountDetails	ReceivableAssetAmountDetails READONLY,
@JobStepInstanceId BIGINT
)
AS
BEGIN
UPDATE VAT
SET ReceivableDetailAmount = RA.AssetExtendedPrice,IsLateFeeProcessed=1
FROM VATReceivableDetailExtract VAT
JOIN @receivableAssetAmountDetails RA ON VAT.ReceivableDetailId=RA.ReceivableDetailId AND VAT.AssetId=RA.AssetId
WHERE VAT.JobStepInstanceId=@JobStepInstanceId

END

GO
