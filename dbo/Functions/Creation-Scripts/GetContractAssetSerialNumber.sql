SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetContractAssetSerialNumber]
(
@AssetId BIGINT,
@ContractId BIGINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
--DECLARE @AssetId BIGINT
--DECLARE     @ContractId BIGINT
--SET @AssetId=103709
--SET @ContractId=26701
              
DECLARE @SerialNumber NVARCHAR(MAX)
SET @SerialNumber=''
SELECT @SerialNumber =@SerialNumber +SerialNumber+','
FROM (
SELECT SerialNumber = CASE WHEN COUNT(ASN.Id) = 1 THEN  MAX(ASN.SerialNumber) ELSE null END
FROM
	(
	SELECT
	AssetId = Assets.Id,
	AssetOrder=ROW_NUMBER() OVER(Partition BY LeaseAssets.LeaseFinanceId ORDER BY LeaseAssets.Id DESC)
	FROM LeaseFinances
	INNER JOIN LeaseAssets ON LeaseFinances.Id=LeaseAssets.LeaseFinanceId AND LeaseFinances.IsCurrent=1 AND LeaseFinances.ContractId=@ContractId
	INNER JOIN Assets ON Assets.Id=LeaseAssets.AssetId AND Assets.Id!=@AssetId AND IsActive=1
	UNION ALL
	SELECT
	AssetId = Assets.Id,
	AssetOrder=ROW_NUMBER() OVER(Partition BY CollateralAssets.LoanFinanceId ORDER BY CollateralAssets.Id DESC)
	FROM LoanFinances
	INNER JOIN CollateralAssets ON LoanFinances.Id=CollateralAssets.LoanFinanceId AND LoanFinances.IsCurrent=1 AND LoanFinances.ContractId=@ContractId
	INNER JOIN Assets ON Assets.Id=CollateralAssets.AssetId AND Assets.Id!=@AssetId AND IsActive=1
	) AS TEMP 
	LEFT JOIN AssetSerialNumbers ASN on ASN.AssetId = TEMP.AssetId AND ASN.IsActive = 1 
	WHERE AssetOrder<=7
	group by TEMP.AssetId
) AS Temp_ContractsWithAssetSerialNumbers
RETURN REPLACE(REPLACE(@SerialNumber,' ',''),',',' ')
END

GO
