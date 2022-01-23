SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LienFilingStatusForCustomers]
(
@CustomerNumber NVARCHAR(40) = NULL
,@LegalEntity NVARCHAR(MAX) = NULL
,@FilingStatus NVarChar(10) = NULL
,@AsOfDate DATETIME = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
SELECT DISTINCT
Party.PartyNumber AS Customer#
,Party.PartyName AS CustomerName
,LienFiling.Id AS LienID
,LienFiling.LienRefNumber AS LienReference#
,LienResponse.AuthorityFileNumber AS File#
,LienResponse.AuthorityFilingStatus AS FilingStatus
,LienFiling.TransactionType AS TransactionType
,ISNULL(EntityResourcesForState.Value,State.ShortName) AS State
,CONVERT(DATE,ISNULL(LienResponse.UpdatedTime,LienResponse.CreatedTime)) AS StatusDate
,U.FullName AS ExportGeneratedBy
,LegalEntity.LegalEntityNumber AS LegalEntity#
FROM LienFilings LienFiling
JOIN LienResponses LienResponse on LienResponse.Id = LienFiling.Id
JOIN States State on State.Id = LienFiling.StateId
JOIN Users U on U.Id = ISNULL(LienResponse.UpdatedById,LienResponse.CreatedById)
JOIN Parties Party ON Party.Id = LienFiling.CustomerId
LEFT JOIN Contracts Contract ON Contract.Id = LienFiling.ContractId
LEFT JOIN LoanFinances ON Contract.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
LEFT JOIN LeaseFinances ON Contract.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
LEFT JOIN LegalEntities LegalEntity ON LegalEntity.Id = (CASE WHEN (Contract.ContractType = 'Loan' OR Contract.ContractType = 'ProgressLoan') THEN LoanFinances.LegalEntityId ELSE LeaseFinances.LegalEntityId END)
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
ANd EntityResourcesForState.Culture= @Culture
WHERE (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@LegalEntity IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')))
AND (@FilingStatus IS NULL OR LienResponse.AuthorityFilingStatus = @FilingStatus)
AND (@AsOfDate IS NULL OR CAST(LienFiling.CreatedTime AS DATE) <= CAST(@AsOfDate AS DATE))
ORDER BY Party.PartyNumber,LienFiling.Id
END

GO
