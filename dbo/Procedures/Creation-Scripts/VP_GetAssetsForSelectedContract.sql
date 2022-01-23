SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VP_GetAssetsForSelectedContract]
(
@SequenceNumber NVARCHAR(40)=NULL,
@ContractType NVARCHAR(14)=NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF(@ContractType =''Lease'')
BEGIN
;WITH CTE_AssetDetails AS(
SELECT
Asset.Id AS AssetId
,Asset.Alias
,Asset.ParentAssetId AS ParentAssetId
,Asset.Status AS Status
,Manuf.Name AS Manufacturer
,AssetType.Name AS AssetType
,Asset.Description AS Description
FROM Contracts C
JOIN LeaseFinances Lease ON C.Id=Lease.ContractId
AND C.SequenceNumber=@SequenceNumber
JOIN LeaseAssets LeaseAsset ON Lease.Id= LeaseAsset.LeaseFinanceId
JOIN Assets Asset ON  LeaseAsset.AssetId=Asset.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
WHERE Lease.IsCurrent=1
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
ELSE IF(@ContractType =''Loan'')
BEGIN
;WITH CTE_AssetDetails AS(
SELECT
Asset.Id AS AssetId
,Asset.Alias
,Asset.ParentAssetId AS ParentAssetId
,Asset.Status AS Status
,Manuf.Name AS Manufacturer
,AssetType.Name AS AssetType
,Asset.Description AS Description
FROM Contracts C
JOIN LoanFinances Loan ON C.Id= Loan.ContractId
AND C.SequenceNumber= @SequenceNumber
JOIN CollateralAssets LoanAsset ON Loan.Id= LoanAsset.LoanFinanceId
JOIN Assets Asset ON  LoanAsset.AssetId=Asset.Id
LEFT JOIN Manufacturers Manuf ON Asset.ManufacturerId = Manuf.Id
JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
WHERE Loan.IsCurrent=1
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_AssetDetails A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT A.*,ASN.SerialNumber FROM CTE_AssetDetails A
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON A.AssetId = ASN.AssetId 

END
'
EXEC sp_executesql @Sql,N'
@SequenceNumber NVARCHAR(40)=NULL,
@ContractType NVARCHAR(14)
@AssetMultipleSerialNumberType NVARCHAR(10)'
,@SequenceNumber
,@ContractType
,@AssetMultipleSerialNumberType

GO
