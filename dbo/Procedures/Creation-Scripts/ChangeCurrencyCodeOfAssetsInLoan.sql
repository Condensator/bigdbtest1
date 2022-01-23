SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ChangeCurrencyCodeOfAssetsInLoan]
(
@LoanFinanceId BIGINT,
@AssetIdsForCurrencyCode NVARCHAR(MAX),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
CA.AssetId,
CurrencyCode.ISO [CurrencyCode]
INTO #CollateralAssets
FROM CollateralAssets CA
JOIN LoanFinances LF ON CA.LoanFinanceId = LF.Id
JOIN Contracts CS ON LF.ContractId = CS.Id
JOIN Currencies C ON CS.CurrencyId = C.Id
JOIN CurrencyCodes CurrencyCode ON C.CurrencyCodeId = CurrencyCode.Id
WHERE LF.Id = @LoanFinanceId
AND CA.AssetId IN (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIdsForCurrencyCode,','))
UPDATE Assets
SET CurrencyCode = CA.CurrencyCode
,PropertyTaxCost_Currency = CA.CurrencyCode
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
JOIN #CollateralAssets CA ON A.Id = CA.AssetId
END

GO
