SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCollateralAssetsFromLease]
(
@PPCAssetDetails ProgressFundingAssetDetail READONLY
)
AS
BEGIN
SET NOCOUNT ON
UPDATE CA SET CA.IsActive = PD.CollateralAssetActiveStatus, CA.TerminationDate = PD.TerminationDate
FROM CollateralAssets CA
JOIN LoanFinances LF ON CA.LoanFinanceId = LF.Id
JOIN PayableInvoiceAssets PIA ON CA.AssetId = PIA.AssetId
JOIN @PPCAssetDetails PD ON PIA.Id = PD.PayableInvoiceAssetId
WHERE LF.IsCurrent = 1;
END

GO
