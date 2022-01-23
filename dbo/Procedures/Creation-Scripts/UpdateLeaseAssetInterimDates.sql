SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLeaseAssetInterimDates]
(
@LeaseAssetsParam LeaseAssetsUpdateParam READONLY,
@InterimDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
BEGIN TRANSACTION;
BEGIN TRY
UPDATE LeaseAssets
SET
InterimInterestStartDate = @InterimDate,
PaymentDate = @InterimDate,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
InterimInterestProcessedAfterPayment = 0,
InterimRentProcessedAfterPayment = 0
FROM LeaseAssets LA
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN @LeaseAssetsParam assetParam ON LA.AssetId = assetParam.AssetId AND LF.Id = assetParam.LeaseFinanceId
LEFT JOIN LeaseFundings FU ON LA.PayableInvoiceId = FU.FundingId AND LF.Id = FU.LeaseFinanceId
WHERE (UPPER(LFD.InterimAssessmentMethod) = 'BOTH' OR UPPER(LFD.InterimAssessmentMethod) = 'INTEREST')
AND (FU.Id IS NULL OR FU.Type = 'Origination');
UPDATE PayableInvoiceAssets
SET InterimInterestStartDate = @InterimDate, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM PayableInvoiceAssets PIA
JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id
JOIN LeaseFundings FU ON PI.Id = FU.FundingId
JOIN LeaseAssets LA ON FU.LeaseFinanceId = LA.LeaseFinanceId AND PIA.AssetId = LA.AssetId
JOIN LeaseFinanceDetails LFD ON FU.LeaseFinanceId = LFD.Id
JOIN @LeaseAssetsParam assetParam ON LA.AssetId = assetParam.AssetId AND PIA.AssetId = assetParam.AssetId
WHERE (UPPER(LFD.InterimAssessmentMethod) = 'BOTH' OR UPPER(LFD.InterimAssessmentMethod) = 'INTEREST')
AND FU.Type = 'Origination';
UPDATE LeaseAssets
SET
InterimRentStartDate = @InterimDate,
PaymentDate = @InterimDate,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
InterimInterestProcessedAfterPayment = 0,
InterimRentProcessedAfterPayment = 0
FROM LeaseAssets LA
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN @LeaseAssetsParam assetParam ON LA.AssetId = assetParam.AssetId AND LF.Id = assetParam.LeaseFinanceId
LEFT JOIN LeaseFundings FU ON LA.PayableInvoiceId = FU.FundingId AND LF.Id = FU.LeaseFinanceId
WHERE UPPER(LFD.InterimAssessmentMethod) = 'RENT'
AND (FU.Id IS NULL OR FU.Type = 'Origination');
UPDATE LeaseAssets
SET
PaymentDate = @InterimDate,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
InterimInterestProcessedAfterPayment = 0,
InterimRentProcessedAfterPayment = 0
FROM LeaseAssets LA
JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN @LeaseAssetsParam assetParam ON LA.AssetId = assetParam.AssetId AND LF.Id = assetParam.LeaseFinanceId
LEFT JOIN LeaseFundings FU ON LA.PayableInvoiceId = FU.FundingId AND LF.Id = FU.LeaseFinanceId
WHERE UPPER(LFD.InterimAssessmentMethod) = '_'
OR (FU.Id IS NOT NULL AND FU.Type != 'Origination');
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
SELECT ERROR_MESSAGE() info,ERROR_LINE() linenumber
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END

GO
