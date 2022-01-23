SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[StateApportionmentReport]
(
@FromDate AS Date = NULL,
@ToDate AS Date = NULL,
@FromSequenceNumber AS NVARCHAR(80) = NULL,
@ToSequenceNumber AS NVARCHAR(80) = NULL,
@FromAssetId AS BIGINT = NULL,
@ToAssetId AS BIGINT = NULL,
@State AS NVARCHAR(100) = NULL,
@Country AS NVARCHAR(100) = NULL,
@LegalEntityNumber AS NVARCHAR(20) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
WITH CTE_DistinctLocations
AS
(
SELECT
Id,
AssetId,
LocationId,
EffectiveFromDate,
PropertyValueFromDate,
ROW_NUMBER() OVER (PARTITION BY AssetId ORDER BY EffectiveFromDate) AS RowNumber
FROM
(
SELECT
AssetLocations.Id AS Id,
AssetId,
LocationId,
EffectiveFromDate,
EffectiveFromDate AS PropertyValueFromDate,
ROW_NUMBER() OVER (PARTITION BY AssetId,EffectiveFromDate ORDER BY  AssetLocations.Id DESC) AS TopLocation
FROM AssetLocations
JOIN Assets ON AssetLocations.AssetId = Assets.Id AND AssetLocations.IsActive = 1
JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
WHERE LocationId IS NOT NULL
AND(@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND CAST(EffectiveFromDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(EffectiveFromDate AS DATE) <= CAST(@ToDate AS DATE)
) AS OrderedAssetLocations
WHERE TopLocation = 1
),
CTE_RentalAmount
AS
(
SELECT
Contracts.Id AS ContractId,
Contracts.SequenceNumber,
NULL AS TransactionNumber,
CTE_DistinctLocations.LocationId,
SUM(ReceivableDetails.Amount_Amount) AS RentalAmount,
0.0 AS InterestIncome,
0.0 AS PayoffAmount,
0.0 AS BuyoutAmount,
0.0 AS AssetSalesAmount,
MAX(LegalEntities.CurrencyCode) AS CurrencyCode
FROM  Contracts
JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND LeaseFinances.ApprovalStatus = 'Approved'
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND  LeaseAssets.IsTaxDepreciable = 1 AND LeaseAssets.IsActive=1
JOIN ReceivableDetails ON LeaseAssets.AssetId = ReceivableDetails.AssetId AND ReceivableDetails.IsActive = 1
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND  Receivables.EntityId = ContractId AND  Receivables.IsActive = 1 AND Receivables.EntityType='CT'
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id AND ReceivableCodes.IsActive=1
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId= ReceivableTypes.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN  CTE_DistinctLocations ON  ReceivableDetails.AssetId = CTE_DistinctLocations.AssetId
AND CAST(Receivables.DueDate AS DATE) >= CTE_DistinctLocations.EffectiveFromDate AND
CAST(Receivables.DueDate AS DATE) <= @ToDate
WHERE ReceivableTypes.Name IN ('CapitalLeaseRental','InterimRent','OperatingLeaseRental','OverTermRental')
AND	CAST(Receivables.DueDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(Receivables.DueDate AS DATE) <= CAST(@TODATE AS DATE)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND LeaseAssets.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND LeaseAssets.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND LeaseAssets.AssetId BETWEEN @FromAssetId AND @ToAssetId))
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_InterestAmount
AS
(
SELECT
Contracts.Id AS ContractId,
Contracts.SequenceNumber,
NULL AS TransactionNumber,
CTE_DistinctLocations.LocationId,
0.0 AS RentalAmount,
SUM(AssetIncomeSchedules.Income_Amount) AS InterestIncome,
0.0 AS PayoffAmount,
0.0 AS BuyoutAmount,
0.0 AS AssetSalesAmount,
MAX(LegalEntities.CurrencyCode) AS CurrencyCode
FROM Contracts
JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND LeaseFinances.ApprovalStatus = 'Approved'
JOIN LeaseFinanceDetails	ON LeaseFinances.Id = LeaseFinanceDetails.Id AND LeaseFinanceDetails.LeaseContractType <> 'Operating'
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND  LeaseAssets.IsTaxDepreciable = 0
JOIN AssetIncomeSchedules ON LeaseAssets.AssetId = AssetIncomeSchedules.AssetId AND  AssetIncomeSchedules.IsActive = 1
JOIN LeaseIncomeSchedules ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id
AND LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id  AND LeaseIncomeSchedules.IsSchedule = 1
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN  CTE_DistinctLocations ON AssetIncomeSchedules.AssetId = CTE_DistinctLocations.AssetId
AND CAST(LeaseIncomeSchedules.IncomeDate AS DATE) >= CTE_DistinctLocations.EffectiveFromDate
AND CAST(LeaseIncomeSchedules.IncomeDate AS DATE) <= @ToDate
WHERE CAST(LeaseIncomeSchedules.IncomeDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(LeaseIncomeSchedules.IncomeDate AS DATE) <= CAST(@TODATE AS DATE)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND LeaseAssets.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND LeaseAssets.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND LeaseAssets.AssetId BETWEEN @FromAssetId AND @ToAssetId))
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_PayOffAmount
AS
(
SELECT
Contracts.Id AS ContractId,
Contracts.SequenceNumber,
NULL AS TransactionNumber,
CTE_DistinctLocations.LocationId,
0.0 AS RentalAmount,
0.0 AS InterestIncome,
SUM(ReceivableDetails.Amount_Amount) AS PayoffAmount,
0.0 AS BuyoutAmount,
0.0 AS AssetSalesAmount,
MAX(LegalEntities.CurrencyCode) AS CurrencyCode
FROM Payoffs
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1 AND  LeaseFinances.ApprovalStatus = 'Approved'
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
JOIN Receivables ON Receivables.EntityId = Contracts.Id AND  Receivables.EntityType='CT'
AND Receivables.SourceId=Payoffs.Id AND Receivables.SourceTable='LeasePayoff' AND IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id AND ReceivableCodes.IsActive=1
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId= ReceivableTypes.Id AND ReceivableTypes.IsActive=1
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
LEFT JOIN  CTE_DistinctLocations ON ReceivableDetails.AssetId = CTE_DistinctLocations.AssetId
AND CAST(Receivables.DueDate AS DATE) >= CTE_DistinctLocations.EffectiveFromDate AND
CAST(Receivables.DueDate AS DATE) <= @ToDate
WHERE ReceivableTypes.Name = 'LeasePayOff'
AND CAST(Receivables.DueDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(Receivables.DueDate AS DATE) <= CAST(@TODATE AS DATE)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND ReceivableDetails.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND ReceivableDetails.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND ReceivableDetails.AssetId BETWEEN @FromAssetId AND @ToAssetId))
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_BuyOutAmount
AS
(
SELECT
Contracts.Id AS ContractId,
Contracts.SequenceNumber,
NULL AS TransactionNumber,
CTE_DistinctLocations.LocationId,
0.0 AS RentalAmount,
0.0 AS InterestIncome,
0.0 AS PayoffAmount,
SUM(ReceivableDetails.Amount_Amount) AS BuyoutAmount,
0.0 AS AssetSalesAmount,
MAX(LegalEntities.CurrencyCode) AS CurrencyCode
FROM Payoffs
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1 AND  LeaseFinances.ApprovalStatus = 'Approved'
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
JOIN Receivables ON Receivables.EntityId = Contracts.Id AND  Receivables.EntityType='CT'
AND Receivables.SourceId=Payoffs.Id AND Receivables.SourceTable='LeasePayoff' AND IsActive=1
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id AND ReceivableCodes.IsActive=1
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId= ReceivableTypes.Id AND ReceivableTypes.IsActive=1
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
LEFT JOIN  CTE_DistinctLocations ON  ReceivableDetails.AssetId = CTE_DistinctLocations.AssetId
AND CAST(Payoffs.PayoffEffectiveDate AS DATE) >= CTE_DistinctLocations.EffectiveFromDate
AND CAST(Payoffs.PayoffEffectiveDate AS DATE) <= @ToDate
WHERE ReceivableTypes.Name = 'BuyOut'
AND CAST(Receivables.DueDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(Receivables.DueDate AS DATE) <= CAST(@TODATE AS DATE)
AND(@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND ReceivableDetails.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND ReceivableDetails.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND ReceivableDetails.AssetId BETWEEN @FromAssetId AND @ToAssetId))
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_AssetSaleAmount
AS
(
SELECT
0 AS LeaseId,
NULL AS SequenceNumber,
AssetSales.TransactionNumber,
AssetSales.TaxLocationId,
0.0 AS RentalAmount,
0.0 AS InterestIncome,
0.0 AS PayoffAmount,
0.0 AS BuyoutAmount,
SUM(ReceivableDetails.Amount_Amount) AS AssetSalesAmount,
MAX(LegalEntities.CurrencyCode) AS CurrencyCode
FROM AssetSales
JOIN LegalEntities ON AssetSales.LegalEntityId = LegalEntities.Id
JOIN AssetSaleReceivables ON AssetSaleReceivables.AssetSaleId = AssetSales.Id AND AssetSaleReceivables.IsActive = 1 AND @FromSequenceNumber IS NULL
JOIN ReceivableDetails ON AssetSaleReceivables.ReceivableId = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive = 1
JOIN Locations ON AssetSales.TaxLocationId = Locations.Id
JOIN States ON Locations.StateId = States.Id
JOIN Countries ON States.CountryId = Countries.Id
WHERE(@State IS NULL OR States.LongName = @State)
AND(@Country IS NULL OR Countries.LongName = @Country)
AND (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND ReceivableDetails.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND ReceivableDetails.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND ReceivableDetails.AssetId BETWEEN @FromAssetId AND @ToAssetId))
GROUP BY
AssetSales.TransactionNumber,
AssetSales.TaxLocationId
),
CTE_PropertyBeginValue
AS
(
SELECT
Contracts.Id AS ContractId,
SequenceNumber,
CTE_DistinctLocations.LocationId,
SUM(NBV_Amount) AS BeginPropertyValue
FROM Contracts
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND IsCurrent=1 AND  LeaseFinances.ApprovalStatus = 'Approved'
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1 AND LeaseAssets.IsTaxDepreciable = 1
LEFT JOIN TaxDepEntities ON LeaseAssets.AssetId = TaxDepEntities.AssetId
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN  CTE_DistinctLocations ON LeaseAssets.AssetId = CTE_DistinctLocations.AssetId
AND CAST(TaxDepEntities.DepreciationBeginDate AS DATE) >= CTE_DistinctLocations.PropertyValueFromDate
AND CAST(TaxDepEntities.DepreciationBeginDate AS DATE) <= @ToDate
WHERE(@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND LeaseAssets.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND LeaseAssets.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND LeaseAssets.AssetId BETWEEN @FromAssetId AND @ToAssetId))
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND (CAST(TaxDepEntities.DepreciationBeginDate AS DATE) <  CAST(@FromDate AS DATE))
AND (TaxDepEntities.TerminationDate IS NULL OR (CAST(TaxDepEntities.TerminationDate AS DATE) > CAST(@FromDate AS DATE)))
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_PropertyEndValue
AS
(
SELECT
Contracts.Id AS ContractId,
SequenceNumber,
CTE_DistinctLocations.LocationId,
SUM(LeaseAssets.NBV_Amount) AS EndPropertyValue
FROM  Contracts
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND IsCurrent=1 AND  LeaseFinances.ApprovalStatus = 'Approved'
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND LeaseAssets.IsActive = 1 AND LeaseAssets.IsTaxDepreciable = 1
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN TaxDepEntities ON LeaseAssets.AssetId = TaxDepEntities.AssetId
LEFT JOIN  CTE_DistinctLocations ON LeaseAssets.AssetId = CTE_DistinctLocations.AssetId
AND CAST(TaxDepEntities.DepreciationBeginDate AS DATE) >= CTE_DistinctLocations.PropertyValueFromDate
AND CAST(TaxDepEntities.DepreciationBeginDate AS DATE) <= @ToDate
WHERE(@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND (TaxDepEntities.TerminationDate IS NULL OR (CAST(TaxDepEntities.TerminationDate AS DATE) > CAST(@ToDate AS DATE)))
AND ((@State IS NULL AND @Country IS NULL) OR CTE_DistinctLocations.LocationId IS NOT NULL)
AND ((@FromAssetId IS NULL AND @ToAssetId IS NULL)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NULL AND LeaseAssets.AssetId = @FromAssetId)
OR (@ToAssetId IS NOT NULL AND @FromAssetId IS NULL AND LeaseAssets.AssetId = @ToAssetId)
OR (@FromAssetId IS NOT NULL AND @ToAssetId IS NOT NULL AND LeaseAssets.AssetId BETWEEN @FromAssetId AND @ToAssetId))
AND ((@FromSequenceNumber IS NULL AND @ToSequenceNumber IS NULL)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NULL AND Contracts.SequenceNumber = @FromSequenceNumber)
OR (@ToSequenceNumber IS NOT NULL AND @FromSequenceNumber IS NULL AND Contracts.SequenceNumber = @ToSequenceNumber)
OR (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber))
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
CTE_DistinctLocations.LocationId
),
CTE_Result
AS
(
SELECT * FROM CTE_RentalAmount
UNION ALL
SELECT * FROM CTE_InterestAmount
UNION ALL
SELECT * FROM CTE_PayOffAmount
UNION ALL
SELECT * FROM CTE_BuyOutAmount
UNION ALL
SELECT * FROM  CTE_AssetSaleAmount
)
SELECT
ISNULL(Locations.Code,'Everywhere') AS Location,
CTE_Result.SequenceNumber,
TransactionNumber,
ISNULL(CTE_PropertyBeginValue.BeginPropertyValue,0.00) AS BeginPropertyValue,
ISNULL(CTE_PropertyEndValue.EndPropertyValue,0.00) AS EndPropertyValue,
RentalAmount,
InterestIncome,
PayoffAmount,
BuyOutAmount,
AssetSalesAmount,
ISNULL(EntityResourceForState.Value,States.LongName) AS State,
CurrencyCode AS Currency
FROM CTE_Result
LEFT JOIN CTE_PropertyBeginValue ON CTE_PropertyBeginValue.ContractId = CTE_Result.ContractId
AND CTE_PropertyBeginValue.LocationId = CTE_Result.LocationId
LEFT JOIN CTE_PropertyEndValue ON CTE_PropertyEndValue.ContractId = CTE_Result.ContractId
AND CTE_PropertyEndValue.LocationId = CTE_Result.LocationId
LEFT JOIN Locations  ON CTE_Result.LocationId = Locations.Id
LEFT JOIN States ON Locations.StateId = States.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=States.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='LongName'
AND EntityResourceForState.Culture=@Culture
END

GO
