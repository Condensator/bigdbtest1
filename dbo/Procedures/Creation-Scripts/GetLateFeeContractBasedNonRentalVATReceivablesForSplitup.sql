SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLateFeeContractBasedNonRentalVATReceivablesForSplitup]
(
@BatchSplitCountSize BIGINT,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SELECT DISTINCT
TOP (@BatchSplitCountSize)
STC.ReceivableDetailId
,STC.AssetId
,CustomerCost
,VAT.ReceivableDetailAmount ExtendedPrice
INTO #ReceivableAssetDetails
FROM
SalesTaxContractBasedSplitupReceivableDetail_Extract STC
JOIN VATReceivableDetailExtract VAT ON STC.ReceivableDetailId = VAT.ReceivableDetailId
AND STC.JobStepInstanceId = VAT.JobStepInstanceId AND STC.JobStepInstanceId = @JobStepInstanceId
JOIN Receivables R ON VAT.ReceivableId=R.Id AND R.SourceTable='LateFee'
WHERE IsLateFeeProcessed = 0

SELECT
ReceivableDetailId
,ExtendedPrice
FROM
#ReceivableAssetDetails
GROUP BY
ReceivableDetailId
,ExtendedPrice

SELECT * FROM  #ReceivableAssetDetails

UPDATE VAT 
SET IsLateFeeProcessed = 1
FROM VATReceivableDetailExtract VAT
JOIN #ReceivableAssetDetails RAD ON VAT.ReceivableDetailId=RAD.ReceivableDetailId AND VAT.AssetId=RAD.AssetId
WHERE VAT.JobStepInstanceId=@JobStepInstanceId

END

GO
