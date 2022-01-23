SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VATInvoiceReportAddendum]
(
@InvoiceId BIGINT
) WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;
--Declare	@InvoiceId BIGINT = 133411
--To get the selected dynamic location Information from Bill To
DECLARE @Locations TABLE (Location NVARCHAR(100))
DECLARE @UseDynamicContentForInvoiceAddendum BIT;
SET @UseDynamicContentForInvoiceAddendum = (SELECT bt.UseDynamicContentForInvoiceAddendumBody from dbo.BillToes bt WHERE Id = (select ri.BillToId from ReceivableInvoices ri where ri.Id = @InvoiceId))
IF(@UseDynamicContentForInvoiceAddendum = 1)
BEGIN
INSERT INTO @Locations SELECT AttributeName FROM BillToInvoiceAddendumBodyDynamicContents BIABDC
JOIN ReceivableInvoices RI ON BIABDC.BillToId = RI.BillToId
JOIN InvoiceAddendumBodyDynamicContents IABDC ON BIABDC.InvoiceAddendumBodyDynamicContentId = IABDC.Id
AND AttributeName In ('AddressLine1','AddressLine2','City','ShortName','PostalCode','Division')
AND IABDC.IsActive = 1
AND IncludeInInvoice = 1
WHERE RI.Id =  @InvoiceId
END
ELSE
BEGIN
INSERT INTO @Locations SELECT IABDC.AttributeName
FROM InvoiceAddendumBodyDynamicContents IABDC
WHERE IABDC.AttributeName In ('AddressLine1','AddressLine2','City','ShortName','PostalCode','Division')
AND IABDC.IsActive = 1
END
DECLARE @AddressLine1Exists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'AddressLine1')
DECLARE @AddressLine2Exists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'AddressLine2')
DECLARE @CityExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'City')
DECLARE @DivisionExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'Division')
DECLARE @StateShortNameExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'ShortName')
DECLARE @PostalCodeExists INT = (SELECT COUNT(*) FROM @Locations WHERE Location = 'PostalCode')
CREATE TABLE #TaxHeader(InvoiceId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,ReceivableCodeId BIGINT);
CREATE TABLE #ImpositionDetails(InvoiceId BIGINT,ReceivableTaxDetailId BIGINT,AssetId BIGINT,Rent DECIMAL(16,2),Amount DECIMAL(16,2),ExternalJurisdictionId INT,ImpositionType NVARCHAR(MAX),ReceivableCodeId BIGINT);
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
/*This block is to calculate the interest amount that needs to be shown as a separate element in the addendum
not sure whether this applicable for Generic Invoice format but if the user selects this element in the billto then
this part will calculate that amount*/
/*Region Starts*/
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
INNER JOIN dbo.FloatRateIndexDetails fr ON lfr.FloatRateIndexDetailId = fr.Id
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
SELECT ai.AssetId,SUM(ISNULL(fr.FloatRateAmount,0) + ISNULL(ai.IncomeAmount,0)) LeaseInterestAmount
INTO #LeaseIncomeResult
FROM #AssetIncomeAmount ai
LEFT JOIN  #FloatRateAmount fr ON fr.AssetId = ai.AssetId
GROUP BY ai.AssetId
SELECT iabdc.AttributeName,bt.Id BillToId, ri.Id InvoiceId
INTO #DynamicAddendum
FROM  dbo.ReceivableInvoices ri
INNER JOIN dbo.BillToes bt ON ri.BillToId = bt.Id
INNER JOIN dbo.BillToInvoiceAddendumBodyDynamicContents btiabdc ON btiabdc.BillToId = bt.Id
INNER JOIN dbo.InvoiceAddendumBodyDynamicContents iabdc ON iabdc.Id = btiabdc.InvoiceAddendumBodyDynamicContentId
where btiabdc.IncludeInInvoice = 1 AND ri.Id = @InvoiceId
;WITH CTE_dynamic as
(
SELECT TOP 1 iabdc.AttributeName,bt.Id BillToId,ri.Id 'InvoiceId' FROM  dbo.ReceivableInvoices ri
INNER JOIN dbo.BillToes bt ON ri.BillToId = bt.Id
INNER JOIN dbo.BillToInvoiceAddendumBodyDynamicContents btiabdc ON btiabdc.BillToId = bt.Id
INNER JOIN dbo.InvoiceAddendumBodyDynamicContents iabdc ON iabdc.Id = btiabdc.InvoiceAddendumBodyDynamicContentId
WHERE btiabdc.IncludeInInvoice = 1 AND ri.Id = @InvoiceId
ORDER BY btiabdc.Id
)
SELECT
DISTINCT
InvoiceNumber,
InvoiceType,
InvoiceNumberLabel,
InvoiceRunDateLabel,
InvoiceRunDate,
DueDate,
SequenceNumber,
CustomerNumber,
InvoiceExtractReceivableDetails.AssetId,
AssetSerialNumber,
AssetDescription,
AssetPurchaseOrderNumber 'CustomerPurchaseOrderNumber',
CASE WHEN EXISTS(SELECT * FROM #DynamicAddendum WHERE AttributeName = 'LeaseInterestAmount') THEN
ISNULL(InvoiceExtractReceivableDetails.ReceivableAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) - ISNULL(id.AssetLevelInterestAmount * InvoiceExtractReceivableDetails.ExchangeRate,0)
ELSE ISNULL(InvoiceExtractReceivableDetails.ReceivableAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) END 'Rent',
ISNULL(InvoiceExtractReceivableDetails.TaxAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) 'SalesTax',
ISNULL(InvoiceExtractReceivableDetails.ReceivableAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0)
+ ISNULL(InvoiceExtractReceivableDetails.TaxAmount_Amount * InvoiceExtractReceivableDetails.ExchangeRate,0) 'AssetTotal',
@UseDynamicContentForInvoiceAddendum UseDynamicContentForInvoiceAddendumBody,
'ShowAssetId' = CASE cd.AttributeName WHEN 'Id' THEN 1 ELSE 0 END,
'ShowAssetSerialNumber' = CASE cd.AttributeName WHEN 'SerialNumber' THEN 1 ELSE 0 END,
'ShowDescription' = CASE cd.AttributeName WHEN 'Description' THEN 1 ELSE 0 END,
'ShowAddressLine1' = CASE cd.AttributeName WHEN 'AddressLine1' THEN 1 ELSE 0 END,
'ShowCustomerPurchaseOrderNumber' = CASE cd.AttributeName WHEN 'CustomerPurchaseOrderNumber' THEN 1 ELSE 0 END,
CASE WHEN iec.AttributeName = 'None' OR iec.AttributeName IS NULL OR iec.GroupAssets = 0 THEN 'SequenceNumber'
WHEN iec.AttributeName = 'Number' THEN 'InvoiceNumber'
ELSE iec.AttributeName END 'AssetGroupByOption',
dbo.GetAddressFormat(id.AssetAddressLine1, id.AssetAddressLine2, id.AssetCity, id.AssetState, NULL) + ' ' + ISNULL(id.AssetPostalCode,'') 'Code',
InvoiceExtractReceivableDetails.PeriodStartDate,InvoiceExtractReceivableDetails.PeriodEndDate
FROM InvoiceExtractCustomerDetails iec
JOIN InvoiceExtractReceivableDetails ON
iec.InvoiceId = InvoiceExtractReceivableDetails.InvoiceId
JOIN #AssetDetails id ON
InvoiceExtractReceivableDetails.InvoiceId = id.InvoiceId
AND InvoiceExtractReceivableDetails.AssetId = id.AssetId
LEFT JOIN CTE_dynamic cd
ON cd.InvoiceId = iec.InvoiceId
WHERE iec.InvoiceId = @InvoiceId
DROP TABLE #AssetDetails
DROP TABLE #FloatRateAmount
DROP TABLE #TaxHeader
DROP TABLE #ImpositionDetails
DROP TABLE #AssetIncomeAmount
DROP TABLE #LeaseIncomeResult
DROP TABLE #DynamicAddendum
END

GO
