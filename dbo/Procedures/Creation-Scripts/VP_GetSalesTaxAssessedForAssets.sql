SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetSalesTaxAssessedForAssets]
(
@AssetIdCSV NVARCHAR(MAX) = NULL,
@EffectiveFromDate DATE = NULL
)
AS
BEGIN
SELECT
DISTINCT
RTD.AssetId
,A.Alias
FROM ReceivableTaxDetails RTD
JOIN ReceivableDetails RD ON RTD.ReceivableDetailId = RD.Id
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN Assets A ON RTD.AssetId = A.Id
WHERE R.DueDate >= @EffectiveFromDate
AND RTD.IsActive = 1 AND R.IsActive = 1
AND RTD.AssetId IN (SELECT Item FROM ConvertCSVToStringTable(@AssetIdCSV,','))
END

GO
