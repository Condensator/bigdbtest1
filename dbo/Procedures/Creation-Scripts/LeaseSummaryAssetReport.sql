SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LeaseSummaryAssetReport]
(
@SequenceNumber  NVARCHAR(40),
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;

;WITH CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM Contracts 
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND IsCurrent = 1
INNER JOIN LeaseAssets ON LeaseFinances.Id =  LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL) 
INNER JOIN Assets ON LeaseAssets.AssetId =  Assets.Id
INNER JOIN AssetSerialNumbers ASN on Assets.Id = ASN.AssetId AND ASN.IsActive=1
WHERE Contracts.SequenceNumber=@SequenceNumber 
GROUP BY ASN.AssetId
)

SELECT
Assets.Id  AS AssetId,
LeaseAssets.ReferenceNumber,
Assets.FinancialType,
Manufacturers.Name AS Manufacturer,
Assets.PartNumber,
ASN.SerialNumber,
CONCAT(Locations.AddressLine1+', ',Locations.AddressLine2+', ',Locations.City+', ',States.ShortName+', ',Countries.ShortName+', ',Locations.PostalCode) AS Location,
LeaseAssets.NBV_Amount,
LeaseAssets.Rent_Amount,
LeaseAssets.BookedResidual_Amount,
LeaseAssets.IsTaxDepreciable,
LeaseAssets.IsActive,
AssetTypes.Name AS AssetType,
LeaseAssets.IsLeaseAsset,
LeaseAssets.IsSaleLeaseback,
LeaseAssets.IsFailedSaleLeaseback,
LeaseAssets.FMV_Amount,
LeaseAssets.MaturityPayment_Amount
FROM
Contracts
INNER JOIN
LeaseFinances ON Contracts.Id = LeaseFinances.ContractId AND IsCurrent = 1
INNER JOIN
LeaseAssets ON LeaseFinances.Id =  LeaseAssets.LeaseFinanceId AND (LeaseAssets.IsActive=1 OR LeaseAssets.TerminationDate IS NOT NULL)
INNER JOIN
Assets ON LeaseAssets.AssetId =  Assets.Id
INNER JOIN
AssetTypes ON Assets.TypeId = AssetTypes.Id
LEFT JOIN
CTE_AssetSerialNumberDetails ASN ON Assets.Id =  ASN.AssetId 
LEFT JOIN
Manufacturers ON Assets.ManufacturerId = Manufacturers.Id
LEFT JOIN
AssetLocations ON Assets.Id = AssetLocations.AssetId AND AssetLocations.IsCurrent=1 AND AssetLocations.IsActive=1
LEFT JOIN
Locations ON AssetLocations.LocationId = Locations.Id
LEFT JOIN
States ON Locations.StateId = States.Id
LEFT JOIN
Countries ON States.CountryId = Countries.Id
WHERE
Contracts.SequenceNumber=@SequenceNumber 

END

GO
