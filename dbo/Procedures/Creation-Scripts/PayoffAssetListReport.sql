SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PayoffAssetListReport]
(
@CustomerID BIGINT = NULL
,@ContractID BIGINT = NULL
,@AsOfDate DATETIME = NULL
,@PayoffId BIGINT = NULL
,@CustomerNumber NVARCHAR(100) = NULL
,@SequenceNumber NVARCHAR(100) = NULL
,@QuoteName NVARCHAR(100) = NULL
,@AccessibleLegalEntityIds NVARCHAR(MAX) = NULL
,@CurrentPortfolioId BIGINT =NULL
,@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @CustomerID BIGINT = 2608
--DECLARE @ContractID BIGINT = 109273
--DECLARE @AsOfDate DATETIME = GETDATE()
--DECLARE @PayoffId BIGINT = 439
--EXEC [dbo].[PayoffAssetListReport] @CustomerID = NULL, @ContractID = NULL,@AsOfDate = N'2/16/2016',@PayoffId=39,@CustomerNumber=NULL,@SequenceNumber=NULL,@QuoteNumber=NULL
WITH CTE_PayoffAssetDetail AS
(
SELECT
Parties.PartyNumber AS CustomerNumber
,SequenceNumber
,Payoffs.Id AS PayoffQuoteId
,QuoteName AS PayoffQuoteNumber
,Payoffs.PayoffEffectiveDate TerminationDate
,Payoffs.PayoffAmount_Currency AS Currency
,Assets.Id AS AssetId
,PayoffAssets.Status + ' ' + ReturnTo + ' ' + PayoffAssets.SubStatus AS Status
,PayoffAssets.Status PayoffAssetStatus
,PayoffAssets.SubStatus
,ReturnTo
,Locations.Code AS LocationCode
,Manufacturers.Name AS ManufacturerName
,Quantity
,ModelYear
,Assets.Description AS AssetDescription
,AssetCategories.Name AS AssetCategoryName
,LeaseAssets.NBV_Amount AS AssetCost
,Payoffs.Status AS QuoteStatus
,(SELECT FirstName + LastName FROM
(SELECT ID MaxAssignContractId FROM
(SELECT MAX(EmployeesAssignedToContracts.Id) MaxEmployeeAssignId FROM
(SELECT MAX(EmployeesAssignedToContracts.ActivationDate) MaxActivationDate FROM EmployeesAssignedToContracts
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE ContractId = Contracts.Id AND RoleFunctionId=6) MADate
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.ActivationDate = MADate.MaxActivationDate
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id  AND RoleFunctionId=6
WHERE ContractId = Contracts.Id) MId
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.Id = MId.MaxEmployeeAssignId WHERE ContractId = Contracts.Id) EmployeeId
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.Id = EmployeeId.MaxAssignContractId
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
JOIN Users ON EmployeesAssignedToParties.EmployeeId = Users.Id) AccountManagerName
,	(SELECT FirstName + LastName FROM
(SELECT ID MaxAssignContractId FROM
(SELECT MAX(EmployeesAssignedToContracts.Id) MaxEmployeeAssignId FROM
(SELECT MAX(EmployeesAssignedToContracts.ActivationDate) MaxActivationDate FROM EmployeesAssignedToContracts
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
WHERE ContractId = Contracts.Id AND RoleFunctionId=2) MADate
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.ActivationDate = MADate.MaxActivationDate
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id  AND RoleFunctionId=2
WHERE ContractId = Contracts.Id) MId
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.Id = MId.MaxEmployeeAssignId WHERE ContractId = Contracts.Id) EmployeeId
JOIN EmployeesAssignedToContracts ON EmployeesAssignedToContracts.Id = EmployeeId.MaxAssignContractId
JOIN EmployeesAssignedToParties ON EmployeesAssignedToContracts.EmployeeAssignedToPartyId = EmployeesAssignedToParties.Id
JOIN Users ON EmployeesAssignedToParties.EmployeeId = Users.Id) SalesRepName
FROM Payoffs
JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId
JOIN LeaseFinances ON Payoffs.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId AND PayoffAssets.LeaseAssetId = LeaseAssets.Id
JOIN Assets ON LeaseAssets.AssetId = Assets.Id
LEFT JOIN Manufacturers ON Assets.ManufacturerId = Manufacturers.Id
JOIN AssetTypes ON Assets.TypeId = AssetTypes.Id
JOIN (select value as Id from String_split(@AccessibleLegalEntityIds,',')) as AccessibleLegalEntities
ON LeaseFinances.LegalEntityId = AccessibleLegalEntities.Id
LEFT JOIN AssetCategories ON Assets.AssetCategoryId = AssetCategories.Id
LEFT JOIN AssetLocations ON LeaseAssets.AssetId = AssetLocations.AssetId AND AssetLocations.IsCurrent = 1 --PayoffAssets.LocationId = AssetLocations.Id
LEFT JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN Customers ON LeaseFinances.CustomerId = Customers.Id
JOIN Parties ON Customers.Id = Parties.Id
WHERE Payoffs.Status != 'Inactive' AND Payoffs.Status != 'Reversed'
AND ((@CustomerID IS NULL AND Parties.PortfolioId=@CurrentPortfolioId) OR Customers.Id = @CustomerID)
AND (@ContractID IS NULL OR Contracts.Id = @ContractID)
AND (@AsOfDate IS NULL OR CAST(PayoffEffectiveDate AS DATE) <= CAST(@AsOfDate AS DATE))
AND (@PayoffId IS NULL OR payoffs.Id = @PayoffId)
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_PayoffAssetDetail A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT PA.*,ASN.SerialNumber FROM CTE_PayoffAssetDetail PA
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON PA.AssetId = ASN.AssetId 

END

GO
