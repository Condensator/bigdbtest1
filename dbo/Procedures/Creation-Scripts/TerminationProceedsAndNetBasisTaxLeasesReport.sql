SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TerminationProceedsAndNetBasisTaxLeasesReport]
(
@FromDate DATETIMEOFFSET= NULL
,@ToDate DATETIMEOFFSET= NULL
,@TransactionType NVARCHAR(30) = NULL
,@CustomerNumber NVARCHAR(40) = NULL
,@LegalEntityNumber NVARCHAR(MAX) = NULL
,@SequenceNumber NVARCHAR(40) = NULL
,@Culture NVARCHAR(10) = NULL
)
AS
BEGIN

DECLARE @OperatingLeaseContractType NVARCHAR(40) = 'Operating',
@DispositionTypeValue NVARCHAR(40) = 'Inventory Sale',
@PayoffAssetStatus NVARCHAR(40) = 'Return'


--------------------------------------------------Temp Table Creation------------------------------------------------------------------------------------
CREATE TABLE #CommonDetails
(
AssetId													BIGINT,
PostalCode												NVARCHAR(50),
CurrencyId												BIGINT,
CountryShortName										NVARCHAR(50),
StateShortName											NVARCHAR(50),
Division												NVARCHAR(50),
City													NVARCHAR(50),
EndNetBookValue_Amount									DECIMAL(18, 2),
EndNetBookValue_Currency								NVARCHAR(50),
ISO														NVARCHAR(50),
DepreciationDate										DATETIME
)

CREATE TABLE #ReportDetails
(
CustomerNumber											NVARCHAR(50),
CustomerName											NVARCHAR(50),
SequenceNumber											NVARCHAR(50),
Alias													NVARCHAR(50),
LeaseContractType										NVARCHAR(50),
AssetId													BIGINT,
ZipCode													NVARCHAR(50),
IsTaxLease												BIT,
DispositionType											NVARCHAR(50),
DispositionDate											DATETIME,
Proceeds												DECIMAL(18, 2),
NetBasis												DECIMAL(18, 2),
TaxNBV													DECIMAL(18, 2),
CountryName												NVARCHAR(50),
StateName												NVARCHAR(50),
County													NVARCHAR(50),
City													NVARCHAR(50),
Currency												NVARCHAR(50)
)

CREATE TABLE #MaxAssetSaleDepreciationDate
(
AssetId													BIGINT,
MaxDepreciationDate										DATETIME
)
CREATE TABLE #AssetValueHistoryEndBookValue 
(
AssetId													BIGINT,
NetBasis												Decimal(18,2)
)
CREATE TABLE #AssetIncomeScheduleEndBookValue 
(
AssetId													BIGINT,
NetBasis												Decimal(18,2)
)
CREATE TABLE #AssetSaleDetails
(
AssetSaleId                                             BIGINT,
AssetId                                                 BIGINT,
FairMarketValue                                         Decimal(18,2),
Discounts                                               Decimal(18,2),
RetainedPercentage										BIGINT
)
CREATE TABLE #CalculatedFields 
(
AssetId BIGINT,
AssetSaleId BIGINT,
RetainedDiscount Decimal(18,2),
RetainedFairMarketValue Decimal(18,2)
)

--------------------------------------------------Fetch common values for both Payoff and AssetSale------------------------------------------------------------------------------------

;WITH CTE_LatestAssetLocation
AS
(
SELECT
Asset.Id AS AssetId,
MAX(AssetLocation.EffectiveFromDate) as LocationEffectiveDate
FROM Assets Asset
JOIN AssetLocations AssetLocation ON Asset.Id = AssetLocation.AssetId
WHERE AssetLocation.IsActive = 1
AND (@ToDate IS NULL OR CAST(AssetLocation.EffectiveFromDate AS DATE) <= CAST(@ToDate AS DATE))
GROUP BY Asset.Id
)
INSERT INTO #CommonDetails(
AssetId ,
PostalCode ,
CurrencyId,
CountryShortName,
StateShortName,
Division,
City ,
EndNetBookValue_Amount,
EndNetBookValue_Currency ,
ISO,
DepreciationDate
)
SELECT
Assets.Id AS AssetId,
Locations.PostalCode,
TaxDepAmortizationDetails.CurrencyId,
ISNULL(EntityResourceForCountry.Value,Countries.ShortName) AS CountryShortName,
ISNULL(EntityResourceForState.Value,States.ShortName) AS StateShortName,
Locations.Division,
Locations.City,
TaxDepAmortizationDetails.EndNetBookValue_Amount,
TaxDepAmortizationDetails.EndNetBookValue_Currency,
CurrencyCodes.ISO,
TaxDepAmortizationDetails.DepreciationDate
FROM
Assets 
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId AND AssetLocations.IsActive=1
JOIN CTE_LatestAssetLocation ON AssetLocations.AssetId = CTE_LatestAssetLocation.AssetId
AND AssetLocations.EffectiveFromDate = CTE_LatestAssetLocation.LocationEffectiveDate
JOIN Locations ON AssetLocations.LocationId=Locations.Id AND Locations.IsActive=1
JOIN States ON Locations.StateId = States.Id AND States.IsActive=1
JOIN Countries ON States.CountryId = Countries.Id AND Countries.IsActive=1
JOIN TaxDepEntities ON TaxDepEntities.AssetId = Assets.Id AND TaxDepEntities.IsActive = 1
JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id AND TaxDepTemplates.IsActive = 1
JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
AND TaxDepTemplateDetails.TaxBook='Federal'
JOIN TaxDepRates on TaxDepTemplateDetails.TaxDepRateId = TaxDepRates.Id AND TaxDepRates.System!='WDV' AND TaxDepRates.IsActive=1
JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId AND TaxDepAmortizations.IsActive = 1
AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId
AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND TaxDepAmortizationDetails.IsSchedule = 1
JOIN Currencies Currency ON TaxDepAmortizationDetails.CurrencyId = Currency.Id
JOIN CurrencyCodes ON Currency.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=Countries.Id
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='ShortName'
AND EntityResourceForCountry.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=States.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='ShortName'
AND EntityResourceForState.Culture=@Culture

--------------------------------------------------Calculate max depreciation date for asset sale------------------------------------------------------------------------------------

;WITH CTE_CalculatedMaxDepreciationDate
AS
(
SELECT Asset.AssetId as AssetId,
MAX(Asset.DepreciationDate) as MaxDepreciationDate
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id
JOIN #CommonDetails Asset ON Asset.AssetId = AssetSaleDetail.AssetId
WHERE DATEADD(MONTH,1+DATEDIFF(MONTH,0,AssetSale.TransactionDate),-1) >= Asset.DepreciationDate 
GROUP BY Asset.AssetId
)
INSERT INTO #MaxAssetSaleDepreciationDate
(
AssetId,
MaxDepreciationDate
)
SELECT AssetId,MaxDepreciationDate FROM CTE_CalculatedMaxDepreciationDate

--------------------------------------------------Asset sale details to calculate proceeds------------------------------------------------------------------------------------

INSERT INTO #AssetSaleDetails
(
AssetSaleId,
AssetId,
FairMarketValue,
Discounts,
RetainedPercentage
)
SELECT DISTINCT
AssetSale.Id AS AssetSaleId,
AssetDetails.AssetId,
AssetSaleDetail.FairMarketValue_Amount,
AssetSale.Discounts_Amount,
ISNULL(ReceivableForTransfers.RetainedPercentage,100) AS RetainedPercentage
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id 
JOIN #CommonDetails AssetDetails ON AssetSaleDetail.AssetId = AssetDetails.AssetId
LEFT JOIN LeaseAssets LeaseAsset ON AssetDetails.AssetId = LeaseAsset.AssetId AND LeaseAsset.TerminationDate IS NOT NULL
JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId = LeaseFinance.Id and LeaseFinance.IsCurrent = 1
JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinanceDetail.Id = LeaseFinance.Id
JOIN LegalEntities LegalEntity on LeaseFinance.LegalEntityId = LegalEntity.Id
JOIN Contracts Contract ON LeaseFinance.ContractId = Contract.Id
LEFT JOIN ReceivableForTransfers ON ReceivableForTransfers.ContractId = Contract.Id 
AND ReceivableForTransfers.LeaseFinanceId = LeaseFinance.Id AND ReceivableForTransfers.ContractType = Contract.ContractType
AND ReceivableForTransfers.LegalEntityId = LegalEntity.Id

--------------------------------------------------Fetching Report details from Payoff and Asset Sale------------------------------------------------------------------------------------

INSERT INTO #ReportDetails
(
CustomerNumber,
CustomerName,
SequenceNumber,
Alias,
LeaseContractType,
AssetId,                
ZipCode,                             
IsTaxLease,         
DispositionType,
DispositionDate,
Proceeds,
NetBasis,
TaxNBV,
CountryName,
StateName,
County,
City,
Currency                             
)
SELECT
Parties.PartyNumber AS CustomerNumber
,Parties.PartyName  AS CustomerName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseFinanceDetails.LeaseContractType AS LeaseContractType
,AssetDetails.AssetId AS AssetId
,AssetDetails.PostalCode AS ZipCode
,LeaseFinanceDetails.IsTaxLease AS IsTaxLease
,Payoffs.PayoffAssetStatus AS DispositionType 
,CONVERT(VARCHAR(10),Payoffs.PayoffEffectiveDate,111) AS DispositionDate
,CASE WHEN Payoffs.PayoffAssetStatus = @PayoffAssetStatus
               THEN 0.00
               ELSE ISNULL(SUM(ReceivableDetails.Amount_Amount) ,0.00)
               END Proceeds
,0.00 AS NetBasis
,AssetDetails.EndNetBookValue_Amount AS TaxNBV
,AssetDetails.CountryShortName AS CountryName
,AssetDetails.StateShortName AS StateName
,AssetDetails.Division AS County
,AssetDetails.City
,AssetDetails.ISO AS Currency
FROM Payoffs
JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId AND PayoffAssets.IsActive=1
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id AND Payoffs.Status = 'Activated'
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id  AND LeaseFinanceDetails.IsTaxLease=1
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id  AND LeaseFinances.BookingStatus = 'Commenced'
JOIN LeaseAssets ON PayoffAssets.LeaseAssetId = LeaseAssets.Id AND LeaseAssets.IsActive=1
JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
JOIN DealProductTypes ON Contracts.DealProductTypeId = DealProductTypes.Id AND DealProductTypes.IsActive=1
JOIN DealTypes DealType on DealProductTypes.DealTypeId = DealType.Id
JOIN #CommonDetails AssetDetails ON LeaseAssets.AssetId = AssetDetails.AssetId AND Payoffs.Status = 'Activated'
AND AssetDetails.CurrencyId = Contracts.CurrencyId
LEFT JOIN Receivables ON Receivables.EntityId = Contracts.Id AND Receivables.SourceId = Payoffs.Id 
AND Receivables.SourceTable = 'LeasePayoff'
AND Receivables.FunderId is null AND Receivables.IsActive = 1
LEFT JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = Receivables.Id AND ReceivableDetails.AssetId = AssetDetails.AssetId 
AND ReceivableDetails.IsActive = 1
WHERE (@FromDate IS NULL OR CAST(Payoffs.PayoffEffectiveDate AS DATE) >= CAST(@FromDate AS DATE)
AND (@ToDate IS NULL OR CAST(Payoffs.PayoffEffectiveDate AS DATE) <= CAST(@ToDate AS DATE)))
AND  DATEADD(MONTH,1+DATEDIFF(MONTH,0,Payoffs.PayoffEffectiveDate),-1) = AssetDetails.DepreciationDate 
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@TransactionType IS NULL OR DealProductTypes.Name = @TransactionType)
AND (DealProductTypes.Name != 'Synthetic')
AND (@CustomerNumber IS NULL OR Parties.PartyNumber = @CustomerNumber)
GROUP BY
Parties.PartyNumber
,Parties.PartyName
,Contracts.SequenceNumber
,Contracts.Alias
,LeaseFinanceDetails.LeaseContractType
,AssetDetails.CountryShortName
,AssetDetails.StateShortName
,AssetDetails.Division
,AssetDetails.City
,AssetDetails.ISO
,AssetDetails.EndNetBookValue_Amount
,AssetDetails.AssetId
,Payoffs.PayoffEffectiveDate
,AssetDetails.PostalCode
,Payoffs.PayoffAssetStatus
,LeaseFinanceDetails.IsTaxLease

UNION

SELECT
Parties.PartyNumber AS CustomerNumber
,Parties.PartyName  AS CustomerName
,NULL
,NULL
,NULL
,AssetDetails.AssetId AS AssetId
,AssetDetails.PostalCode AS ZipCode
,0 AS IsTaxLease
,@DispositionTypeValue AS DispositionType 
,CONVERT(VARCHAR(10),AssetSale.TransactionDate,111) AS DispositionDate
,0.00 AS Proceeds
,0.00 AS NetBasis
,AssetDetails.EndNetBookValue_Amount AS TaxNBV
,AssetDetails.CountryShortName AS CountryName
,AssetDetails.StateShortName AS StateName
,AssetDetails.Division AS County
,AssetDetails.City
,AssetDetails.ISO AS Currency
FROM AssetSaleDetails AssetSaleDetail
JOIN AssetSales AssetSale ON AssetSaleDetail.AssetSaleId = AssetSale.Id
JOIN #CommonDetails AssetDetails ON AssetSaleDetail.AssetId = AssetDetails.AssetId 
JOIN Parties ON AssetSale.BuyerId = Parties.Id
JOIN #MaxAssetSaleDepreciationDate TaxDepDetail ON TaxDepDetail.AssetId = AssetSaleDetail.AssetId 
WHERE
AssetSaleDetail.IsActive = 1
AND AssetDetails.DepreciationDate = TaxDepDetail.MaxDepreciationDate
AND (@FromDate IS NULL OR CAST(AssetSale.TransactionDate AS DATE) >= CAST(@FromDate AS DATE)
AND (@ToDate IS NULL OR CAST(AssetSale.TransactionDate AS DATE) <= CAST(@ToDate AS DATE)))
AND (@CustomerNumber IS NULL)
AND (@SequenceNumber IS NULL)

--------------------------------------------------Net Basis value------------------------------------------------------------------------------------

INSERT INTO #AssetValueHistoryEndBookValue 
(AssetId,
NetBasis
)
SELECT 
AssetId,
NetBasis
FROM
(
SELECT
ROW_NUMBER() OVER(PARTITION BY ReportDetail.AssetId ORDER BY AssetValueHistories.IncomeDate DESC) AS RowNumber,
ReportDetail.AssetId,
AssetValueHistories.EndBookValue_Amount AS NetBasis
FROM #ReportDetails ReportDetail
JOIN AssetValueHistories ON AssetValueHistories.AssetId = ReportDetail.AssetId AND AssetValueHistories.IsLessorOwned = 1
AND (ReportDetail.LeaseContractType IS NULL OR ReportDetail.LeaseContractType = @OperatingLeaseContractType ) AND AssetValueHistories.IsSchedule = 1 
AND ReportDetail.DispositionDate >= AssetValueHistories.IncomeDate 
) AS LatestAmount
WHERE RowNumber = 1

INSERT INTO #AssetIncomeScheduleEndBookValue 
(AssetId,
NetBasis
)
SELECT 
AssetId,
NetBasis
FROM
(SELECT
ROW_NUMBER() OVER(PARTITION BY ReportDetail.AssetId ORDER BY LeaseIncomeSchedules.IncomeDate DESC) AS RowNumber,
ReportDetail.AssetId,
AssetIncomeSchedules.EndNetBookValue_Amount AS NetBasis
FROM #ReportDetails ReportDetail 
JOIN AssetIncomeSchedules ON ReportDetail.AssetId = AssetIncomeSchedules.AssetId
JOIN LeaseIncomeSchedules on AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id AND AssetIncomeSchedules.IsActive = 1
AND ReportDetail.LeaseContractType != @OperatingLeaseContractType
AND LeaseIncomeSchedules.IsAccounting = 1 AND  LeaseIncomeSchedules.IsSchedule = 1
AND ReportDetail.DispositionDate >= LeaseIncomeSchedules.IncomeDate
) AS LatestAmount
WHERE RowNumber = 1

UPDATE Report SET 
NetBasis = CASE WHEN AssetValueHistories.AssetId IS NOT NULL
                                             THEN AssetValueHistories.NetBasis
                                             ELSE AssetIncomeSchedules.NetBasis
                                             END
FROM #ReportDetails Report      
LEFT JOIN #AssetIncomeScheduleEndBookValue AssetIncomeSchedules ON Report.AssetId = AssetIncomeSchedules.AssetId
LEFT JOIN #AssetValueHistoryEndBookValue AssetValueHistories ON Report.AssetId = AssetValueHistories.AssetId

--------------------------------------------------Proceeds calculation for Asset Sale------------------------------------------------------------------------------------

/*"As Discount in Asset Sale is at header level, to calculate RetainedDiscount for Proceeds calculation,
the iteration happens for each AssetSale such that the header level Discount is prorated
to each Asset in this AssetSale considering FMV as the weightage factor. To avoid rounding issues, 
the discount calculated for the last asset is rounded off."*/

;WITH CTE_RankedAssetSale
AS
(
SELECT
AssetSaleId,
ROW_NUMBER() OVER(ORDER BY AssetSaleId DESC) AS RowNumber
FROM
#AssetSaleDetails
GROUP BY AssetSaleId
)
SELECT * INTO #AssetSaleId FROM CTE_RankedAssetSale

Declare @Count BIGINT = (select count(AssetSaleId) from #AssetSaleId)
DECLARE @TotalSum DECIMAL(18,2)
DECLARE @MaxRank BIGINT 
DECLARE @Rank BIGINT

SELECT 
AssetSaleId,
SUM(FairMarketValue) AS TotalFairMarketValue
INTO
#TotalFairMarketValues
FROM
#AssetSaleDetails
GROUP BY AssetSaleId

--Iterating over each Asset Sale

WHILE @Count > 0 
BEGIN

SET @Rank = 1
SET @TotalSum = 0.00

SELECT 
#AssetSaleDetails.AssetSaleId,
AssetId,
ROW_NUMBER() OVER(PARTITION BY #AssetSaleDetails.AssetSaleId ORDER BY AssetId DESC) AS Rank
INTO
#RankedAssets
FROM 
#AssetSaleDetails 
JOIN #AssetSaleId ON #AssetSaleId.AssetSaleId = #AssetSaleDetails.AssetSaleId
WHERE #AssetSaleId.RowNumber = @Count

SET @MaxRank = (SELECT MAX(Rank) FROM #RankedAssets)

--Iterating over each Asset in the AssetSale

WHILE (@Rank <= @MaxRank)
	BEGIN

	INSERT INTO #CalculatedFields 
	(
	AssetId,
	AssetSaleId,
	RetainedDiscount,
	RetainedFairMarketValue
	)
	SELECT
	DISTINCT
	AssetSale.AssetId,
	Proceeds.AssetSaleId,
	CASE WHEN TotalFairMarketValue != 0 
				THEN CASE WHEN RankedAssets.Rank < @MaxRank OR @MaxRank = 1 OR @TotalSum is null
						THEN (FairMarketValue / TotalFairMarketValue) * Discounts * (RetainedPercentage/100) 
						ELSE (Discounts * (RetainedPercentage/100)) - @TotalSum
						END
				ELSE 0
				END RetainedDiscount,
	(FairMarketValue * (RetainedPercentage / 100)) AS RetainedFairMarketValue
	FROM 
	#RankedAssets RankedAssets
	JOIN #ReportDetails AssetSale ON RankedAssets.AssetId = AssetSale.AssetId
	JOIN #AssetSaleDetails AssetSaleDetail ON RankedAssets.AssetId = AssetSaleDetail.AssetId 
	AND RankedAssets.AssetSaleId = AssetSaleDetail.AssetSaleId
	JOIN #TotalFairMarketValues Proceeds ON Proceeds.AssetSaleId = RankedAssets.AssetSaleId
	WHERE Rank = @Rank

	SET @TotalSum = 
	(SELECT Sum(RetainedDiscount) FROM #CalculatedFields
	JOIN #RankedAssets RankedAssets ON RankedAssets.AssetId = #CalculatedFields.AssetId 
	AND RankedAssets.AssetSaleId = #CalculatedFields.AssetSaleId)

	SET @Rank += 1;

END

UPDATE AssetSale 
SET AssetSale.Proceeds =
RetainedFairMarketValue - RetainedDiscount
FROM 
#ReportDetails AssetSale
JOIN #CalculatedFields Proceeds ON Proceeds.AssetId = AssetSale.AssetId AND AssetSale.DispositionType != @PayoffAssetStatus

SET @Count -= 1
DROP TABLE #RankedAssets

END

--------------------------------------------------Final Report Dataset------------------------------------------------------------------------------------

SELECT 
CustomerNumber,
CustomerName,
SequenceNumber,
Alias,
LeaseContractType,
AssetId,                
ZipCode,                             
IsTaxLease,         
DispositionType,
CONVERT(VARCHAR(10),DispositionDate,111) AS DispositionDate,
Proceeds,
NetBasis,
TaxNBV,
CountryName,
StateName,
County,
City,
Currency
FROM #ReportDetails



DROP TABLE #AssetSaleDetails
DROP TABLE #CommonDetails
DROP TABLE #MaxAssetSaleDepreciationDate
DROP TABLE #ReportDetails
DROP TABLE #AssetIncomeScheduleEndBookValue
DROP TABLE #AssetValueHistoryEndBookValue
DROP TABLE #AssetSaleId
DROP TABLE #CalculatedFields
DROP TABLE #TotalFairMarketValues

END

GO
