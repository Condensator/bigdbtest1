SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LeaseCashReceiptsReport]
(
@PartyId BIGINT = NULL,
@ContractId BIGINT = NULL,
@ContractType AS NVARCHAR(14) = NULL,
@FromDate DATE,
@ToDate DATE
)
AS
BEGIN
SET NOCOUNT ON
IF @ContractType = '_'
SET @ContractType = NULL
CREATE TABLE #ContractInfo
(
ContractID BIGINT,
SequenceNumber NVARCHAR(40),
LegalEntityNumber NVARCHAR(20),
PartyNumber NVARCHAR(40),
CustomerId BIGINT,
PartyName NVARCHAR(250),
ContractType NVARCHAR(14)
)
CREATE TABLE #ReceiptApplicationForEntity
(
EntityId BIGINT,
Name NVARCHAR(21),
TotalAmount DECIMAL(20,2),
AmountApplied_Currency NVARCHAR(3)
)
INSERT INTO #ContractInfo
SELECT
ContractID,
SequenceNumber,
LegalEntityNumber,
PartyNumber,
CustomerId,
PartyName,
ContractType
FROM
(SELECT DISTINCT
Contracts.Id as 'ContractID',
SequenceNumber,
LegalEntityNumber,
PartyNumber,
LeaseFinances.CustomerId,
PartyName,
ContractType
FROM
Contracts JOIN LeaseFinances
ON Contracts.Id = LeaseFinances.ContractId
JOIN LegalEntities
ON LegalEntities.Id = LeaseFinances.LegalEntityId
JOIN LeaseFinanceDetails
ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Parties
ON LeaseFinances.CustomerId = Parties.Id
UNION ALL
SELECT DISTINCT
Contracts.Id as 'ContractID',
SequenceNumber,
LegalEntityNumber,
PartyNumber,
LoanFinances.CustomerId,
PartyName,
ContractType
FROM
Contracts
JOIN LoanFinances
ON Contracts.Id = LoanFinances.ContractId
JOIN LegalEntities
ON LegalEntities.Id = LoanFinances.LegalEntityId
JOIN LeaseFinanceDetails
ON LoanFinances.Id = LeaseFinanceDetails.Id
JOIN Parties
ON LoanFinances.CustomerId = Parties.Id
) as TempTable
WHERE
(@PartyId IS NULL OR CustomerId = @PartyId)
AND (@ContractId IS NULL OR ContractID = @ContractId)
AND (@ContractType IS NULL OR ContractType = @ContractType)
INSERT INTO #ReceiptApplicationForEntity
SELECT
EntityId,
ReceivableTypes.Name,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) as 'TotalAmount',
ReceiptApplicationReceivableDetails.AmountApplied_Currency
FROM
#ContractInfo
JOIN Receivables
ON #ContractInfo.ContractID = Receivables.EntityId
JOIN ReceivableDetails
ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
JOIN ReceiptApplications
ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts
ON Receipts.Id = ReceiptApplications.ReceiptId
JOIN ReceiptTypes
ON ReceiptTypes.Id = Receipts.TypeId
JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Assets
ON Assets.Id = ReceivableDetails.AssetId
WHERE  Receivables.IsActive = 1
AND ReceivableDetails.IsActive = 1
AND Assets.IsSKU = 0 
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Receivables.EntityType = 'CT'
AND Receipts.Status = 'Posted'
AND @FromDate <= Receipts.PostDate
AND Receipts.PostDate <= @ToDate
AND ReceiptMode = 'MoneyOrder'
AND AssetComponentType IN('Lease', '_')
AND ReceivableTypes.Name IN('LeaseInterimInterest',
'InterimRental',
'CapitalLeaseRental',
'OperatingLeaseRental',
'LeaseFloatRateAdj',
'OverTermRental',
'Supplemental')
GROUP BY EntityId, ReceivableTypes.Name, ReceiptApplicationReceivableDetails.AmountApplied_Currency

UNION 

SELECT
EntityId,
ReceivableTypes.Name,
SUM(ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount) as 'TotalAmount',
ReceiptApplicationReceivableDetails.AmountApplied_Currency
FROM
#ContractInfo
JOIN Receivables
ON #ContractInfo.ContractID = Receivables.EntityId
JOIN ReceivableDetails
ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
JOIN ReceiptApplications
ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts
ON Receipts.Id = ReceiptApplications.ReceiptId
JOIN ReceiptTypes
ON ReceiptTypes.Id = Receipts.TypeId
JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Assets
ON Assets.Id = ReceivableDetails.AssetId
WHERE  Receivables.IsActive = 1
AND ReceivableDetails.IsActive = 1
AND Assets.IsSKU = 1
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Receivables.EntityType = 'CT'
AND Receipts.Status = 'Posted'
AND @FromDate <= Receipts.PostDate
AND Receipts.PostDate <= @ToDate
AND ReceiptMode = 'MoneyOrder'
AND ReceivableTypes.Name IN('LeaseInterimInterest',
'InterimRental',
'CapitalLeaseRental',
'OperatingLeaseRental',
'LeaseFloatRateAdj',
'OverTermRental',
'Supplemental')
GROUP BY EntityId, ReceivableTypes.Name, ReceiptApplicationReceivableDetails.AmountApplied_Currency

SELECT DISTINCT
ContractID,
SequenceNumber,
LegalEntityNumber,
PartyNumber,
PartyName as CustomerName,
ContractType,
ISNULL((SELECT SUM(TotalAmount) FROM #ReceiptApplicationForEntity
WHERE Name IN('LeaseInterimInterest','InterimRental')
AND EntityId = ContractID),0) as InterimAmount,
ISNULL((SELECT SUM(TotalAmount) FROM #ReceiptApplicationForEntity
WHERE Name IN('CapitalLeaseRental','OperatingLeaseRental')
AND EntityId = ContractID),0) as FixedTermAmount,
ISNULL((SELECT SUM(TotalAmount) FROM #ReceiptApplicationForEntity
WHERE Name IN('LeaseFloatRateAdj')
AND EntityId = ContractID),0) as FloatRateAdjustment,
ISNULL((SELECT SUM(TotalAmount) FROM #ReceiptApplicationForEntity
WHERE Name IN('OverTermRental','Supplemental')
AND EntityId = ContractID),0) as OTPAmount,AmountApplied_Currency
FROM #ContractInfo
JOIN #ReceiptApplicationForEntity
ON #ReceiptApplicationForEntity.EntityId = #ContractInfo.ContractID
DROP TABLE #ContractInfo
DROP TABLE #ReceiptApplicationForEntity
END

GO
