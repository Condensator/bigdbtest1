SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AssetProfileReport]
(
@LegalEntityId nvarchar(max) = NULL,
@CustomerName nvarchar(max) = NULL,
@SequenceNumber nvarchar(max) = NULL,
@FromAssetId BIGINT = NULL,
@ToAssetId BIGINT = NULL,
@Culture NVARCHAR(10),
@AssetMultipleSerialNumberType NVARCHAR(10)
) WITH RECOMPILE
AS
--DECLARE @LegalEntityName nvarchar(max)
--DECLARE @CustomerName nvarchar(max)
--DECLARE @SequenceNumber nvarchar(max)
--DECLARE @FromAssetId BIGINT
--DECLARE @ToAssetId BIGINT
--SET @LegalEntityName='Bruce Wayne Enterprises' --9
--SET @CustomerName=null --'Customer-01'
--SET @SequenceNumber=null --'58-6'
--SET @FromAssetId=null --20668
--SET @ToAssetId=null --20791
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_SeqNos AS
(
SELECT Assets.Id As AssetId, Contracts.Id As ContractId, Contracts.SequenceNumber,LeaseAssets.BillToId As 'BillToId' FROM Assets
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
WHERE LeaseAssets.IsActive = 1 AND LeaseFinances.BookingStatus != 'Inactive' AND LeaseFinances.IsCurrent = 1   AND Assets.IsReversed = 0
UNION ALL
SELECT  Assets.Id As AssetId, Contracts.Id As ContractId, Contracts.SequenceNumber,Contracts.BillToId As 'BillToId' FROM Assets
JOIN CollateralAssets ON Assets.Id = CollateralAssets.AssetId
JOIN LoanFinances ON CollateralAssets.LoanFinanceId = LoanFinances.Id
JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
WHERE CollateralAssets.IsActive = 1 AND LoanFinances.Status != 'Inactive' AND LoanFinances.IsCurrent = 1  AND Assets.IsReversed = 0
),
CTE_AssetDetails AS (
SELECT
DISTINCT
Assets.Id 'AssetId'
,Assets.[Status] 'Status'
,AssetCategories.Name 'Category'
,AssetTypes.Name  'AssetType'
,Assets.[Description] 'Description'
,ISNULL(Locations.AddressLine1 +
CASE WHEN Locations.AddressLine2 IS NULL THEN '' ELSE ', ' + Locations.AddressLine2 END+
CASE WHEN Locations.City IS NULL THEN '' ELSE ', ' + Locations.City END +
', '+ ISNULL(EntityResourceForState.Value,States.LongName) + ', '+ Locations.PostalCode + ', ' + ISNULL(EntityResourceForCountry.Value,Countries.ShortName) ,'') 'Address'
,Assets.Quantity 'Quantity'
,Manufacturers.Name 'Manufacturer'
,Assets.PartNumber
,LegalEntities.LegalEntityNumber 'LegalEntityNumber'
,CTE_SeqNos.SequenceNumber 'SequenceNumber'
,CASE WHEN ContractBillTo.Id IS NOT NULL THEN ContractBillTo.Name ELSE BillToes.Name END 'BillTo'
FROM
Assets
INNER JOIN LegalEntities
ON Assets.LegalEntityId = LegalEntities.Id
INNER JOIN AssetTypes
ON Assets.TypeId = AssetTypes.Id
LEFT JOIN AssetCategories
ON Assets.AssetCategoryId = AssetCategories.Id
LEFT JOIN Manufacturers
ON Assets.ManufacturerId = Manufacturers.Id
LEFT JOIN Parties
ON Assets.CustomerId = Parties.Id
LEFT JOIN AssetLocations
ON Assets.Id = AssetLocations.AssetId
AND AssetLocations.IsCurrent = 1
LEFT JOIN Locations
ON AssetLocations.LocationId = Locations.Id
AND Locations.IsActive = 1
LEFT JOIN States
ON  Locations.StateId = States.Id
LEFT JOIN EntityResources EntityResourceForState
ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name ='LongName'
AND EntityResourceForState.Culture = @Culture
LEFT JOIN Countries
ON States.CountryId = Countries.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON Countries.Id = EntityResourceForCountry.EntityId
AND EntityResourceForCountry.EntityType = 'Country'
AND EntityResourceForCountry.Name ='ShortName'
AND EntityResourceForCountry.Culture = @Culture
LEFT JOIN CTE_SeqNos
ON Assets.Id = CTE_SeqNos.AssetId
LEFT JOIN BillToes
ON Assets.CustomerId = BillToes.CustomerId
AND BillToes.IsPrimary = 1 AND Assets.Status = 'Inventory' AND BillToes.IsActive = 1
LEFT JOIN BillToes ContractBillTo
ON ContractBillTo.Id = CTE_SeqNos.BillToId
WHERE
Assets.IsReversed = 0
AND (( @ToAssetId IS NULL AND ( @FromAssetId IS NULL OR Assets.Id = @FromAssetID )) OR (@ToAssetId IS NOT NULL
AND Assets.Id >= @FromAssetId AND Assets.Id <= @ToAssetId ))
AND (@CustomerName IS NULL OR @CustomerName = Parties.PartyName)
AND (@SequenceNumber IS NULL OR @SequenceNumber = CTE_SeqNos.SequenceNumber)
AND (@LegalEntityId IS NULL OR LegalEntities.Id in (select value from String_split(@LegalEntityId,',')))
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM (SELECT DISTINCT AssetId FROM CTE_AssetDetails) A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT A.*,ASN.SerialNumber FROM CTE_AssetDetails A
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON A.AssetId = ASN.AssetId 

END

GO
