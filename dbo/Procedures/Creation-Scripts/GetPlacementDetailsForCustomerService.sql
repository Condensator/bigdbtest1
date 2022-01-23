SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPlacementDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@UserID BIGINT
)
AS
BEGIN
DECLARE @CustomerId BigInt
SET @CustomerId = (Select Id from Parties where PartyNumber = @CustomerNumber)
SELECT DISTINCT C.[Id] INTO #ValidContractIds
FROM
(SELECT C.ID
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = @UserId AND C.[IsConfidential] = 1
UNION
SELECT Id FROM Contracts WHERE IsConfidential = 0) C
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_#ValidContractIds_Id' AND object_id = OBJECT_ID('#ValidContractIds'))
BEGIN
CREATE NONCLUSTERED INDEX IX_#ValidContractIds_Id ON [dbo].[#ValidContractIds] ( [Id] ) ;
END
SELECT
AgencyLegalPlacements.PlacementNumber
,AgencyLegalPlacements.[DateOfPlacement]
,AgencyLegalPlacements.[Status]
,Contracts.SequenceNumber
,Parties.PartyName [CustomerName]
,Parties.PartyNumber [CustomerNumber]
,SUM(ISNULL(AcceleratedBalanceDetails.Balance_Amount, 0)) [Balance_Amount]
,CurrencyCodes.ISO [Balance_Currency]
,Vendor.PartyName [AgencyOrAttorneyAssigned]
,AgencyLegalPlacements.Id [PlacementId]
,AgencyLegalPlacements.IsActive [Active]
FROM AgencyLegalPlacements
INNER JOIN Parties ON AgencyLegalPlacements.CustomerId = Parties.Id
INNER JOIN AgencyLegalPlacementContracts ON AgencyLegalPlacements.Id = AgencyLegalPlacementContracts.AgencyLegalPlacementId
INNER JOIN Contracts ON AgencyLegalPlacementContracts .ContractId = Contracts.Id
INNER JOIN Currencies ON Contracts.CurrencyId = Currencies.Id
INNER JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN Parties [Vendor] ON AgencyLegalPlacements.VendorId = Vendor.Id
LEFT JOIN AcceleratedBalanceDetails ON AgencyLegalPlacementContracts.AcceleratedBalanceDetailId = AcceleratedBalanceDetails.Id
WHERE AgencyLegalPlacements.CustomerId = @CustomerId
AND Contracts.ID IN (SELECT ID FROM #ValidContractIds)
AND AgencyLegalPlacements.IsActive = 1
AND AgencyLegalPlacementContracts.IsActive = 1
GROUP BY   AgencyLegalPlacements.PlacementNumber
,AgencyLegalPlacements.[DateOfPlacement]
,AgencyLegalPlacements.[Status]
,Contracts.SequenceNumber
,Parties.PartyName
,Parties.PartyNumber
,CurrencyCodes.ISO
,Vendor.PartyName
,AgencyLegalPlacements.Id
,AgencyLegalPlacements.IsActive
DROP TABLE #ValidContractIds
END

GO
