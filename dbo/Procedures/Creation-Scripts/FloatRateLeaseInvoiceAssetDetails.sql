SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FloatRateLeaseInvoiceAssetDetails]
(
@InvoiceId BIGINT
)WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @InvoiceId BIGINT = 49070;
--To get the selected dynamic location Information from Bill To
DECLARE @Locations TABLE (Location NVARCHAR(100))
INSERT INTO @Locations SELECT AttributeName FROM BillToInvoiceAddendumBodyDynamicContents BIABDC
JOIN ReceivableInvoices RI ON BIABDC.BillToId = RI.BillToId
JOIN InvoiceAddendumBodyDynamicContents IABDC ON BIABDC.InvoiceAddendumBodyDynamicContentId = IABDC.Id
AND AttributeName In ('AddressLine1','AddressLine2','City','ShortName','PostalCode','Division')
AND IABDC.IsActive = 1
AND IncludeInInvoice = 1
WHERE RI.Id =  @InvoiceId
DECLARE @AddressLine1Exists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'AddressLine1')
DECLARE @AddressLine2Exists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'AddressLine2')
DECLARE @CityExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'City')
DECLARE @DivisionExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'Division')
DECLARE @StateShortNameExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'ShortName')
DECLARE @PostalCodeExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'PostalCode')
CREATE TABLE #AssetDetails(InvoiceId BIGINT,AssetId BIGINT,AssetReceivableAmount DECIMAL(16,2),AssetAddressLine1 NVARCHAR(50)
,AssetAddressLine2 NVARCHAR(50),AssetCity NVARCHAR(40),AssetDivision NVARCHAR(40),AssetState NVARCHAR(5),AssetPostalCode NVARCHAR(12)
,AssetCountry NVARCHAR(5),AssetLevelInterestAmount DECIMAL(16,2))
INSERT INTO #AssetDetails
SELECT
InvoiceExtractCustomerDetails.InvoiceId,
AssetId,
ReceivableAmount_Amount,
CASE WHEN @AddressLine1Exists > 0 THEN AssetAddressLine1 ELSE NULL END 'AssetAddressLine1',
CASE WHEN @AddressLine2Exists > 0 THEN AssetAddressLine2 ELSE NULL END 'AssetAddressLine2',
CASE WHEN @CityExists > 0 THEN AssetCity ELSE NULL END 'AssetCity',
CASE WHEN @DivisionExists > 0 THEN AssetDivision ELSE NULL END 'AssetDivision',
CASE WHEN @StateShortNameExists > 0 THEN AssetState ELSE NULL END 'AssetState',
CASE WHEN @PostalCodeExists > 0 THEN AssetPostalCode ELSE NULL END 'AssetPostalCode',
AssetCountry,
0.00
FROM InvoiceExtractCustomerDetails
JOIN InvoiceExtractReceivableDetails ON
InvoiceExtractCustomerDetails.InvoiceId = InvoiceExtractReceivableDetails.InvoiceId
WHERE InvoiceExtractCustomerDetails.InvoiceId = @InvoiceId
;WITH AssetFloatRateIncomeId AS
(
SELECT DISTINCT lfr.Id LeaseFloatRateIncomeId
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LeasePaymentSchedules lp ON r.PaymentScheduleId = lp.Id
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LeaseFinances lf2 ON c.Id = lf2.ContractId
INNER JOIN dbo.LeaseFinanceDetails lf3 ON lf2.Id = lf3.Id
INNER JOIN dbo.LeaseFloatRateIncomes lfr ON lf2.Id = lfr.LeaseFinanceId
AND lfr.IsAccounting = 1 AND lfr.IsScheduled = 1
--INNER JOIN dbo.FloatRateIndexDetails fr ON lfr.FloatRateIndexDetailId = fr.Id
AND lfr.IncomeDate BETWEEN lp.StartDate AND lp.EndDate
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
)
SELECT afi.AssetId, SUM(CustomerReceivableAmount_Amount) FloatRateAmount
INTO #FloatRateAmount
FROM dbo.AssetFloatRateIncomes afi
INNER JOIN AssetFloatRateIncomeId af ON afi.LeaseFloatRateIncomeId = af.LeaseFloatRateIncomeId
AND afi.IsActive = 1
GROUP BY afi.AssetId
;WITH LeaseIncome AS
(
SELECT DISTINCT lis.Id LeaseIncomeId, lf3.ClassificationContractType
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.LeasePaymentSchedules lp ON r.PaymentScheduleId = lp.Id
INNER JOIN dbo.Contracts c ON rid.EntityId = c.Id
INNER JOIN dbo.LeaseFinances lf2 ON c.Id = lf2.ContractId
INNER JOIN dbo.LeaseFinanceDetails lf3 ON lf2.Id = lf3.Id
INNER JOIN dbo.LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf2.Id
AND lis.IsAccounting = 1 AND lis.IsSchedule = 1
AND lis.IncomeDate BETWEEN lp.StartDate AND lp.EndDate
WHERE ri.IsActive = 1 AND ri.Id = @InvoiceId
)
SELECT ais.AssetId,
CASE li.ClassificationContractType WHEN 'DirectFinance' THEN SUM(ais.Income_Amount)
WHEN 'Operating' THEN SUM(ais.RentalIncome_Amount)
ELSE 0 END IncomeAmount
INTO #AssetIncomeAmount
FROM dbo.AssetIncomeSchedules ais
INNER JOIN LeaseIncome li ON ais.LeaseIncomeScheduleId = li.LeaseIncomeId
AND ais.IsActive = 1
GROUP BY ais.AssetId,li.ClassificationContractType
SELECT fr.AssetId,SUM(fr.FloatRateAmount + ai.IncomeAmount) LeaseInterestAmount
INTO #LeaseIncomeResult
FROM #FloatRateAmount fr
INNER JOIN #AssetIncomeAmount ai ON fr.AssetId = ai.AssetId
GROUP BY fr.AssetId
UPDATE #AssetDetails SET AssetLevelInterestAmount = ISNULL(lir.LeaseInterestAmount,0)
FROM #AssetDetails id
INNER JOIN #LeaseIncomeResult lir ON id.AssetId = lir.AssetId
SELECT iabdc.AttributeName,bt.Id BillToId,ri.Id InvoiceId
INTO #DynamicTemp
FROM  dbo.ReceivableInvoices ri
INNER JOIN dbo.BillToes bt ON ri.BillToId = bt.Id
INNER JOIN dbo.BillToInvoiceAddendumBodyDynamicContents btiabdc
ON btiabdc.BillToId = bt.Id
INNER JOIN dbo.InvoiceAddendumBodyDynamicContents iabdc
ON iabdc.Id = btiabdc.InvoiceAddendumBodyDynamicContentId
WHERE btiabdc.IncludeInInvoice = 1 AND ri.Id = @InvoiceId
;WITH CTE_Dynamic as
(
SELECT TOP 1 iabdc.AttributeName,bt.Id BillToId,ri.Id 'InvoiceId' FROM  dbo.ReceivableInvoices ri
INNER JOIN dbo.BillToes bt ON ri.BillToId = bt.Id
INNER JOIN dbo.BillToInvoiceAddendumBodyDynamicContents btiabdc ON btiabdc.BillToId = bt.Id
INNER JOIN dbo.InvoiceAddendumBodyDynamicContents iabdc ON iabdc.Id = btiabdc.InvoiceAddendumBodyDynamicContentId
WHERE btiabdc.IncludeInInvoice = 1 AND ri.Id = @InvoiceId
ORDER BY btiabdc.Id
)
SELECT
InvoiceNumber,
InvoiceType,
InvoiceNumberLabel,
InvoiceRunDateLabel,
InvoiceRunDate,
DueDate,
SequenceNumber,
InvoiceExtractReceivableDetails.AssetId,
u_CustomerReference1 CustomerReference1,
u_CustomerReference2 CustomerReference2,
u_CustomerReference3 CustomerReference3,
u_CustomerReference4 CustomerReference4,
u_CustomerReference5 CustomerReference5,
AssetSerialNumber,
AssetDescription,
AssetPurchaseOrderNumber 'CustomerPurchaseOrderNumber',
CASE WHEN EXISTS(SELECT * FROM #DynamicTemp WHERE AttributeName = 'LeaseInterestAmount') THEN
ISNULL(id.AssetReceivableAmount,0) - ISNULL(id.AssetLevelInterestAmount,0)
ELSE ISNULL(id.AssetReceivableAmount,0) END 'Rent',
ISNULL(TaxAmount_Amount,0) 'SalesTax',
ISNULL(AssetReceivableAmount + TaxAmount_Amount,0) 'AssetTotal',
UseDynamicContentForInvoiceAddendumBody,
'ShowAssetId' = CASE cd.AttributeName WHEN 'Id' THEN 1 ELSE 0 END,
'ShowAssetSerialNumber' = CASE cd.AttributeName WHEN 'SerialNumber' THEN 1 ELSE 0 END,
'ShowDescription' = CASE cd.AttributeName WHEN 'Description' THEN 1 ELSE 0 END,
'ShowAddressLine1' = CASE cd.AttributeName WHEN 'AddressLine1' THEN 1 ELSE 0 END,
'ShowCustomerPurchaseOrderNumber' = CASE cd.AttributeName WHEN 'CustomerPurchaseOrderNumber' THEN 1 ELSE 0 END,
'ShowCustomerReference1' = CASE cd.AttributeName WHEN 'u_CustomerReference1' THEN 1 ELSE 0 END,
'ShowCustomerReference2' = CASE cd.AttributeName WHEN 'u_CustomerReference2' THEN 1 ELSE 0 END,
'ShowCustomerReference3' = CASE cd.AttributeName WHEN 'u_CustomerReference3' THEN 1 ELSE 0 END,
'ShowCustomerReference4' = CASE cd.AttributeName WHEN 'u_CustomerReference4' THEN 1 ELSE 0 END,
'ShowCustomerReference5' = CASE cd.AttributeName WHEN 'u_CustomerReference5' THEN 1 ELSE 0 END,
CASE WHEN iec.AttributeName = 'None' OR iec.AttributeName IS NULL OR iec.GroupAssets = 0 THEN 'SequenceNumber'
WHEN iec.AttributeName = 'Number' THEN 'InvoiceNumber'
WHEN iec.AttributeName = 'u_CustomerReference1' THEN 'CustomerReference1'
WHEN iec.AttributeName = 'u_CustomerReference2' THEN 'CustomerReference2'
WHEN iec.AttributeName = 'u_CustomerReference3' THEN 'CustomerReference3'
WHEN iec.AttributeName = 'u_CustomerReference4' THEN 'CustomerReference4'
WHEN iec.AttributeName = 'u_CustomerReference5' THEN 'CustomerReference5'
ELSE iec.AttributeName END 'AssetGroupByOption',
dbo.GetAddressFormat(id.AssetAddressLine1, id.AssetAddressLine2, id.AssetCity, id.AssetState, NULL) + ' ' + ISNULL(id.AssetPostalCode,'') 'Code',
ISNULL(id.AssetLevelInterestAmount,0) 'AssetLevelInterestAmount'
FROM InvoiceExtractCustomerDetails iec
JOIN InvoiceExtractReceivableDetails ON
iec.InvoiceId = InvoiceExtractReceivableDetails.InvoiceId
JOIN #AssetDetails id ON
InvoiceExtractReceivableDetails.InvoiceId = id.InvoiceId
AND InvoiceExtractReceivableDetails.AssetId = id.AssetId
LEFT JOIN CTE_dynamic cd
ON cd.InvoiceId = iec.InvoiceId
WHERE iec.InvoiceId = @InvoiceId
DROP TABLE #AssetDetails;
DROP TABLE #FloatRateAmount;
DROP TABLE #AssetIncomeAmount;
DROP TABLE #LeaseIncomeResult;
DROP TABLE #DynamicTemp;
END

GO
