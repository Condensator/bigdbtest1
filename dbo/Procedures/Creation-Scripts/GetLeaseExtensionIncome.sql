SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetLeaseExtensionIncome]
(
@FromDate DATE
,@ToDate DATE
,@TaxProductTypeId DECIMAL = NULL
,@ContractId DECIMAL = NULL
,@LegalEntityId NVARCHAR(MAX) = NULL
,@Culture NVARCHAR(10)
)
AS
DECLARE @Query NVARCHAR(MAX)
BEGIN
SET NOCOUNT ON;
WITH CTE_AssetLocationDetails
AS
(
SELECT
Party.PartyNumber CustomerNumber
,Party.PartyName CustomerName
,CT.SequenceNumber ContractSequenceNumber
,LFD.LeaseContractType LeaseClassificationType
,LOC.Code LocationCode
,ISNULL(EntityResourceForCountry.Value,Country.LongName) CountryName
,ISNULL(EntityResourceForState.Value,ST.LongName) StateName
,LOC.Division
,LOC.City
,AT.Id AssetId
--,LF.Id LeaseFinanceId
FROM Parties Party
INNER JOIN Customers Customer ON Party.Id = Customer.Id
INNER JOIN LeaseFinances LF ON Customer.Id = LF.CustomerId AND LF.IsCurrent = 1
INNER JOIN Contracts CT ON LF.ContractId = CT.Id
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets AT ON LA.AssetId = AT.Id
LEFT JOIN AssetLocations AL ON AL.AssetId = AT.Id AND AL.IsCurrent = 1
LEFT JOIN Locations LOC ON LOC.Id = AL.LocationId
LEFT JOIN States ST ON LOC.StateId = ST.Id
LEFT JOIN Countries Country ON Country.Id = ST.CountryId
INNER JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
LEFT JOIN EntityResources EntityResourceForState
ON ST.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'LongName'
AND EntityResourceForState.Culture = @Culture
LEFT JOIN EntityResources EntityResourceForCountry
ON Country.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name = 'LongName'
AND EntityResourceForCountry.Culture = @Culture
LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
LEFT JOIN TaxProductTypes TPT ON LF.TaxProductTypeId = TPT.Id
AND (@TaxProductTypeId IS NULL OR @TaxProductTypeId = 0 OR TPT.Id = @TaxProductTypeId)
WHERE (@ContractId IS NULL OR @ContractId = 0 OR CT.Id = @ContractId)
AND (@LegalEntityId IS NULL OR @LegalEntityId = '' OR LE.Id in (SELECT value
FROM STRING_SPLIT(@LegalEntityId,',')))
AND(AL.IsCurrent = 1 OR LA.AssetId not in ( SELECT LeaseAssets.AssetId from LeaseFinances
INNER JOIN Contracts  ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
INNER JOIN LeaseAssets  ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
INNER JOIN AssetLocations ON AssetLocations.AssetId = LeaseAssets.AssetId AND AssetLocations.IsCurrent = 1
WHERE Contracts.Id=@ContractId
)))
,CTE_AssetIncomeSchedule AS
(
SELECT
CTE_ALD.AssetId
,SUM(AIS.RentalIncome_Amount) RentalIncomeAmount
,AIS.ResidualIncome_Currency RentalIncomeAmount_Currency
FROM CTE_AssetLocationDetails CTE_ALD
JOIN AssetIncomeSchedules AIS ON AIS.AssetId = CTE_ALD.AssetId
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
WHERE LIS.IsLessorOwned = 1 AND AIS.IsActive = 1
AND (LIS.IncomeDate >= @FromDate AND LIS.IncomeDate < @ToDate)
AND (LIS.IncomeType='OverTerm' OR LIS.IncomeType='Supplemental')
GROUP BY
CTE_ALD.AssetId
,AIS.ResidualIncome_Currency
)
SELECT
CustomerNumber
,CustomerName
,ContractSequenceNumber
,LeaseClassificationType
,LocationCode
,CountryName
,StateName
,Division
,City
,SUM(RentalIncomeAmount) RentalIncomeAmount
,RentalIncomeAmount_Currency RentalIncomeCurrency
FROM CTE_AssetLocationDetails CTE_ALD
JOIN CTE_AssetIncomeSchedule CTE_AIS ON CTE_ALD.AssetId = CTE_AIS.AssetId
GROUP BY
CustomerNumber
,CustomerName
,ContractSequenceNumber
,LeaseClassificationType
,LocationCode
,CountryName
,StateName
,Division
,City
,RentalIncomeAmount_Currency
END

GO
