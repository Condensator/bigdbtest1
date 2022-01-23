SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LienFilingHistoryForCustomers]
(
@CustomerNumber NVARCHAR(40) = NULL
,@LegalEntity NVARCHAR(MAX) = NULL
,@AsOfDate DATETIME = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
WITH LFHCustomer_CTE
AS
(
SELECT LienRecordStatusHistories.Id,LienRecordStatusHistories.LienFilingId,LienRecordStatusHistories.CreatedById,LienRecordStatusHistories.HistoryDate,LienRecordStatusHistories.FileNumber,LienRecordStatusHistories.FilingStatus
FROM LienRecordStatusHistories WHERE Id IN (
Select MAX(LienRecordStatusHistories.Id) 'Id' FROM LienRecordStatusHistories
JOIN LienFilings on LienRecordStatusHistories.LienFilingId = LienFilingId
GROUP BY LienRecordStatusHistories.LienFilingId)
)
SELECT
p.PartyNumber 'Customer#',
p.PartyName 'CustomerName'
,LegalEntity.LegalEntityNumber AS LegalEnity#
,LienFiling.Id AS LienID
,LFHCustomer_CTE.FileNumber AS File#
,LienFiling.TransactionType AS TransactionType
,ISNULL(EntityResourcesForState.Value,State.ShortName) AS State
,LFHCustomer_CTE.HistoryDate AS StatusDate
,ISNULL(LFHCustomer_CTE.FilingStatus,'_') AS FilingStatus
,U.FullName AS UserName
FROM LienFilings LienFiling
JOIN States State ON State.Id = LienFiling.StateId
JOIN dbo.Parties p ON LienFiling.CustomerId = p.Id
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
AND EntityResourcesForState.Culture= @Culture
LEFT JOIN LFHCustomer_CTE ON LienFiling.Id = LFHCustomer_CTE.LienFilingId
LEFT JOIN Users U ON U.Id = LFHCustomer_CTE.CreatedById
LEFT JOIN dbo.Contracts c ON LienFiling.ContractId = c.Id
LEFT JOIN dbo.LeaseFinances lf2 ON lf2.ContractId = c.Id AND lf2.IsCurrent = 1
LEFT JOIN dbo.LoanFinances lf3 ON lf3.ContractId = c.Id AND lf3.IsCurrent = 1
LEFT JOIN LegalEntities LegalEntity ON LegalEntity.Id = ISNULL(lf2.LegalEntityId,lf3.LegalEntityId)
WHERE (@CustomerNumber IS NULL OR p.PartyNumber = @CustomerNumber)
AND (@LegalEntity  IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')) )
AND (@AsOfDate IS NULL OR CAST(LFHCustomer_CTE.HistoryDate AS date) <= CAST(@AsOfDate AS date))
END

GO
