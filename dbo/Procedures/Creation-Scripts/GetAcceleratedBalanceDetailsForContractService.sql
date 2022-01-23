SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAcceleratedBalanceDetailsForContractService]
(
@ContractSequenceNumber nvarchar(50),
@FilterCustomerId BIGINT = NULL,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @ContractId BigInt
SET @ContractId = (Select Id from Contracts where SequenceNumber = @ContractSequenceNumber)
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')
SELECT Contracts.SequenceNumber
,AcceleratedBalanceDetails.[Number]
,AcceleratedBalanceDetails.[AsofDate]
,AcceleratedBalanceDetails.[DateofDefault]
,AcceleratedBalanceDetails.[MaturityDate]
,AcceleratedBalanceDetails.[Status]
,AcceleratedBalanceDetails.[CurrentLegalBalance]
,AcceleratedBalanceDetails.[BalanceType]
,AcceleratedBalanceDetails.[Balance_Amount]
,AcceleratedBalanceDetails.[Balance_Currency]
,AcceleratedBalanceDetails.Id [AcceleratedBalanceId]
,Parties.PartyName [CustomerName]
,Parties.PartyNumber [CustomerNumber]
,Users.FullName [LastModifiedUser]
,LegalEntities.LegalEntityNumber
,LineofBusinesses.Name [LineofBusinesses]
,CASE WHEN AcceleratedBalanceDetails.Status = 'Review' THEN 1 WHEN AcceleratedBalanceDetails.Status = 'Active' THEN 2 ELSE 3 END [SortOrder]
FROM [dbo].AcceleratedBalanceDetails
INNER JOIN Parties ON AcceleratedBalanceDetails.CustomerId = Parties.Id
INNER JOIN LegalEntities ON AcceleratedBalanceDetails.LegalEntityId = LegalEntities.Id
INNER JOIN #AccessibleLegalEntityIds ON LegalEntities.Id = #AccessibleLegalEntityIds.Id
INNER JOIN LineofBusinesses ON AcceleratedBalanceDetails.LineofBusinessId = LineofBusinesses.Id
INNER JOIN ((SELECT LeaseFinances.CustomerId ,SequenceNumber , ContractId ,ContractType  FROM LeaseFinances
INNER JOIN Contracts LeaseContract
ON LeaseFinances.ContractId = LeaseContract.Id
AND LeaseFinances.IsCurrent = 1)
UNION
(SELECT LoanFinances.CustomerId ,SequenceNumber , ContractId , ContractType From LoanFinances
INNER JOIN Contracts LoanContract
ON LoanFinances.ContractId = LoanContract.Id
AND LoanFinances.IsCurrent = 1)) Contracts ON AcceleratedBalanceDetails.ContractId = Contracts.ContractId
LEFT JOIN Users ON AcceleratedBalanceDetails.UpdatedById = Users.Id
WHERE Contracts.ContractId = @ContractId
AND AcceleratedBalanceDetails.CurrentLegalBalance = 1
AND (@FilterCustomerId IS NULL OR AcceleratedBalanceDetails.CustomerId = @FilterCustomerId )
ORDER BY SortOrder , AsofDate DESC
END

GO
