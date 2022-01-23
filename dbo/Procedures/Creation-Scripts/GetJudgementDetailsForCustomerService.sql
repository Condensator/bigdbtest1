SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetJudgementDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@UserId BIGINT,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN
DECLARE @CustomerId BigInt
SET @CustomerId = (Select Id from Parties where PartyNumber = @CustomerNumber)
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')
SELECT Contracts.SequenceNumber
,CourtFilings.CaseNumber
,CourtFilingActions.LegalAction
,[Judgements].[Status]
,[Judgements].[JudgementDate]
,[Judgements].[Amount_Amount]
,[Judgements].[Amount_Currency]
,[Judgements].[Fees_Amount]
,[Judgements].[Fees_Currency]
,[Judgements].[TotalAmount_Amount]
,[Judgements].[TotalAmount_Currency]
,[Judgements].[InterestRate]
,[Judgements].[InterestGrantedFromDate]
,[Judgements].[ExpirationDate]
,[Judgements].[RenewalDate]
,[Judgements].[IsActive]
,[Judgements].[JudgementNumber]
,CAST([Judgements].Id AS BIGINT ) [JudgementId]
FROM [dbo].[Judgements]
INNER JOIN ((SELECT LeaseFinances.CustomerId ,SequenceNumber , ContractId  FROM LeaseFinances
INNER JOIN #AccessibleLegalEntityIds ON LeaseFinances.LegalEntityId = #AccessibleLegalEntityIds.Id
INNER JOIN Contracts LeaseContract
ON LeaseFinances.ContractId = LeaseContract.Id
AND LeaseFinances.IsCurrent = 1
AND (LeaseContract.IsConfidential = 0  OR
LeaseContract.ID IN	(SELECT C.[Id]
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = @UserId AND C.[IsConfidential] = 1) ))
UNION
(SELECT LoanFinances.CustomerId ,SequenceNumber , ContractId From LoanFinances
INNER JOIN #AccessibleLegalEntityIds ON LoanFinances.LegalEntityId = #AccessibleLegalEntityIds.Id
INNER JOIN Contracts LoanContract
ON LoanFinances.ContractId = LoanContract.Id
AND LoanFinances.IsCurrent = 1
AND (LoanContract.IsConfidential = 0 OR
LoanContract.ID IN	(SELECT C.[Id]
FROM  [dbo].[Contracts] AS C
INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
INNER JOIN [dbo].[EmployeesAssignedToParties] AS EACu ON EAC.[EmployeeAssignedToPartyId] = EACu.[Id]
WHERE EACu.[EmployeeId] = @UserId AND C.[IsConfidential] = 1)))) Contracts ON Judgements.ContractId = Contracts.ContractId
LEFT JOIN CourtFilings ON Judgements.CourtFilingId = CourtFilings.Id
LEFT JOIN CourtFilingActions ON Judgements.CourtFilingActionId = CourtFilingActions.Id
WHERE Contracts.CustomerId = @CustomerId
ORDER BY IsActive DESC , JudgementDate DESC
END

GO
