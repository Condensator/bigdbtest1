SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PreQuoteContractReceivableDetails]
(
@ContractIdCSV nvarchar(max),
@AssetIdCSV nvarchar(max)
)
AS
BEGIN
SET NOCOUNT ON
SELECT * INTO #ContractIds FROM ConvertCSVToBigIntTable(@ContractIdCSV, ',');
SELECT
Receivables.Id ReceivableId,
SUM(ReceivableDetails.Amount_Amount) Amount,
SUM (ReceivableDetails.Balance_Amount) Balance,
Receivables.SourceId SourceId,
Receivables.SourceTable SourceTable,
Receivables.EntityId EntityId,
ReceivableCategories.Name ReceivableCategory,
ReceivableTypes.Name ReceivableType,
Receivables.IncomeType IncomeType
INTO #ReceivableTemp
FROM Receivables
INNER JOIN #ContractIds ON Receivables.EntityId = #ContractIds.Id
INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
INNER JOIN ReceivableCodes ON ReceivableCodes.Id = Receivables.ReceivableCodeId
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
INNER JOIN ReceivableCategories ON ReceivableCodes.ReceivableCategoryId = ReceivableCategories.Id
WHERE Receivables.IsActive = 1 AND ReceivableDetails.IsActive = 1
AND Receivables.EntityType = 'CT'
AND ReceivableDetails.BilledStatus = 'Invoiced'
GROUP BY
Receivables.Id,
Receivables.SourceId,
Receivables.SourceTable,
Receivables.EntityId,
ReceivableCategories.Name,
ReceivableTypes.Name,
Receivables.IncomeType
SELECT * INTO #AssetIds FROM ConvertCSVToBigIntTable(@AssetIdCSV, ',');
SELECT #ReceivableTemp.EntityId ContractId,
SUM(ReceivableDetails.Balance_Amount) Balance
INTO #OTPTemp
FROM #ReceivableTemp
INNER JOIN ReceivableDetails ON #ReceivableTemp.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
INNER JOIn #AssetIds ON #AssetIds.Id = ReceivableDetails.AssetId
WHERE (#ReceivableTemp.IncomeType = 'OTP' or #ReceivableTemp.IncomeType = 'Supplemental')
GROUP BY #ReceivableTemp.EntityId
SELECT
#ReceivableTemp.EntityId ContractId,
#ReceivableTemp.ReceivableId ReceivableId,
LateFeeReceivables.Amount_Amount LateFee
INTO #LateFeeTemp
FROM LateFeeReceivables
INNER JOIN #ReceivableTemp ON LateFeeReceivables.Id = #ReceivableTemp.SourceId
WHERE #ReceivableTemp.SourceTable = 'LateFee' AND LateFeeReceivables.EntityType = 'Contract' AND
LateFeeReceivables.EntityId = #ReceivableTemp.EntityId
SELECT Sundries.Id SundryId,
Sundries.ContractId ContractId,
#ReceivableTemp.Balance,
#ReceivableTemp.ReceivableCategory ReceivableCategory,
#ReceivableTemp.ReceivableId ReceivableId
INTO #SundryTemp
FROM Sundries
INNER JOIN #ReceivableTemp ON Sundries.ReceivableId = #ReceivableTemp.ReceivableId
WHERE Sundries.EntityType = 'CT' AND Sundries.ContractId = #ReceivableTemp.EntityId
AND Sundries.IsActive = 1 AND (#ReceivableTemp.ReceivableType = 'Sundry' or #ReceivableTemp.ReceivableType = 'SundrySeperate')
SELECT *
INTO #OtherChargeTemp
FROM #SundryTemp
WHERE ReceivableCategory != 'Maintenance'
SELECT *
INTO #MaintenanceTemp
FROM #SundryTemp
WHERE ReceivableCategory = 'Maintenance'
SELECT
#ReceivableTemp.EntityId AS ContractId,
#ReceivableTemp.ReceivableId AS ReceivableId,
CAST(0 AS DECIMAL(18,2)) AS LateFee,
CAST(0 AS DECIMAL(18,2)) AS OtherCharge,
CAST(0 AS DECIMAL(18,2)) AS Maintenance
INTO #ResultSetTemp
FROM #ReceivableTemp
UPDATE #ResultSetTemp SET LateFee = #LateFeeTemp.LateFee
FROM #LateFeeTemp
INNER JOIN #ResultSetTemp ON #ResultSetTemp.ReceivableId = #LateFeeTemp.ReceivableId
UPDATE #ResultSetTemp SET OtherCharge = #OtherChargeTemp.Balance
FROM #OtherChargeTemp
INNER JOIN #ResultSetTemp ON #ResultSetTemp.ReceivableId = #OtherChargeTemp.ReceivableId
UPDATE #ResultSetTemp SET Maintenance = #MaintenanceTemp.Balance
FROM #MaintenanceTemp
INNER JOIN #ResultSetTemp ON #MaintenanceTemp.ReceivableId = #ResultSetTemp.ReceivableId
SELECT
ContractId,
SUM(LateFee) AS LateFee,
SUM(OtherCharge) AS OtherCharge,
SUM(Maintenance) AS Maintenance,
CAST(0 AS DECIMAL(18,2)) AS OTPRent
INTO #FinalResultTemp
FROM #ResultSetTemp
GROUP BY ContractId
UPDATE #FinalResultTemp SET OTPRent = #OTPTemp.Balance
FROM #OTPTemp
INNER JOIN #FinalResultTemp ON #OTPTemp.ContractId = #FinalResultTemp.ContractId
SELECT * FROM #FinalResultTemp;
DROP TABLE #ContractIds
DROP TABLE #AssetIds
DROP TABLE #ReceivableTemp
DROP TABLE #LateFeeTemp
DROP TABLE #SundryTemp
DROP TABLE #OtherChargeTemp
DROP TABLE #MaintenanceTemp
DROP TABLE #ResultSetTemp
DROP TABLE #OTPTemp
DROP TABLE #FinalResultTemp
END

GO
