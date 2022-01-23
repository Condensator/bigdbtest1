SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AdvancedBilling]
(
@EntityType NVARCHAR(40),
@CustomerNumber NVARCHAR(40) = NULL,
@CustomerName NVARCHAR(MAX) = NULL,
@ContractSequenceNumber NVARCHAR(40) = NULL,
@LegalEntity NVARCHAR(MAX) = NULL,
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET
)
AS
select legalentities.LegalEntityNumber,
receivable.TotalAmount_Currency,
customer.PartyName,
contracts.ContractType,
contracts.SequenceNumber,
rtlc.Name,
receivable.TotalBalance_Amount 'Balance',
receivablegljournal.PostDate,
receivable.DueDate
from Receivables receivable
INNER JOIN Parties customer ON receivable.CustomerId = customer.Id
INNER JOIN ReceivableGLJournals receivablegljournal ON receivablegljournal.ReceivableId = receivable.Id
INNER JOIN GLJournals gljournals ON receivablegljournal.GLJournalId = gljournals.Id
INNER JOIN LegalEntities legalentities ON gljournals.LegalEntityId = legalentities.Id
INNER JOIN ReceivableCodes receivablecode ON receivable.ReceivableCodeId = receivablecode.Id
INNER JOIN dbo.ReceivableCategories rc2 ON rc2.Id = receivablecode.ReceivableCategoryId
INNER JOIN ReceivableTypes receivabletype ON receivabletype.Id = receivablecode.ReceivableTypeId
INNER JOIN dbo.ReceivableTypeLabelConfigs rtlc ON rtlc.ReceivableCategoryId = rc2.Id AND rtlc.ReceivableTypeId = receivabletype.Id AND rtlc.IsDefault = 1 AND rtlc.IsActive = 1
LEFT JOIN Contracts contracts ON contracts.Id = receivable.EntityId AND receivable.EntityType = 'CT'
WHERE (receivablegljournal.PostDate >= @FromDate AND receivablegljournal.PostDate <= @ToDate)
AND (@CustomerNumber IS NULL OR customer.PartyNumber = @CustomerNumber)
AND (receivablegljournal.PostDate < receivable.DueDate)
AND (@CustomerName IS NULL OR customer.PartyName = @CustomerName)
AND (@ContractSequenceNumber IS NULL OR contracts.SequenceNumber = @ContractSequenceNumber)
AND (@EntityType = 'Customer' OR contracts.ContractType = @EntityType)
AND (@LegalEntity IS NULL OR legalentities.LegalEntityNumber in (select value from String_split(@LegalEntity,',')))
GROUP BY legalentities.LegalEntityNumber, receivable.TotalAmount_Currency,customer.PartyName,contracts.ContractType,
contracts.SequenceNumber,rtlc.Name,receivablegljournal.PostDate,receivable.DueDate,receivable.TotalBalance_Amount
ORDER BY legalentities.LegalEntityNumber,customer.PartyName,contracts.SequenceNumber

GO
