SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateCollateralAssetAmountFromDisbursmentRequest]
(
@collateralAssetUpdateParam CollaterAssetAmountUpdateParam READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
BEGIN TRANSACTION;
BEGIN TRY
UPDATE CollateralAssets
SET AcquisitionCost_Amount = PIA.AcquisitionCost_Amount * P.ExchangeRate
,UpdatedById=@UpdatedById
,UpdatedTime=@UpdatedTime
FROM CollateralAssets CA
JOIN Assets A ON CA.AssetId = A.Id
JOIN PayableInvoiceAssets PIA ON A.Id = PIA.AssetId
JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id
JOIN LoanFundings LF ON PI.Id = LF.FundingId
JOIN @collateralAssetUpdateParam P ON PI.Id = P.ProgressLoanInvoiceId AND LF.LoanFinanceId = P.LoanFinanceId
;
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
