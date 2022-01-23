SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[GLJournalView]
AS
SELECT
GLJournalDetails.GLJournalId, PostDate,	GLJournalDetails.EntityType, GLJournalDetails.EntityId,GLJournalDetails.SourceId,
GLTransactionTypes.Name GLTransactionType,GLEntryItems.Name EntryItem, GLJournalDetails.GLAccountNumber,
CASE WHEN GLJournalDetails.IsDebit = 1 THEN Amount_Amount ELSE 0 END Debit,
CASE WHEN GLJournalDetails.IsDebit = 0 THEN Amount_Amount ELSE 0 END Credit,
CASE WHEN GLJournalDetails.IsDebit = 1 THEN 'Debit' ELSE 'Credit' End [Debit/Credit],
Amount_Currency Currency,
GLJournalDetails.Description,IsManualEntry,IsReversalEntry,M2.Name MatchingGLTransactionType, M1.Name MatchingEntryItem, Amount_Amount,
LegalEntityNumber, 	LegalEntities.Name LegalEntityName,GLAccounts.Name GLAccountName,GLAccountTypes.AccountType,
GLAccountTypes.Classification,GLUserBooks.Name GLUserBooksName,GLJournalDetails.ExportJobId, GLJournalDetails.CreatedTime
FROM
GLJournals
JOIN GLJournalDetails on GLJournals.Id = GLJournalDetails.GLJournalId AND GLJournalDetails.IsActive = 1
JOIN GLAccounts on GLJournalDetails.GLAccountId = GLAccounts.Id
JOIN LegalEntities on GLJournals.LegalEntityId = LegalEntities.Id
JOIN GLAccountTypes on GLAccounts.GLAccountTypeId = GLAccountTypes.Id
LEFT JOIN GLTemplateDetails on GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id
LEFT JOIN GLUserBooks on GLAccounts.GLUserBookId = GLUserBooks.Id
LEFT JOIN GLEntryItems on GLTemplateDetails.EntryItemId = GLEntryItems.Id
LEFT JOIN GLTransactionTypes on GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN GLTemplateDetails M on GLJournalDetails.MatchingGLTemplateDetailId = M.Id
LEFT JOIN GLEntryItems M1 on M.EntryItemId = M1.Id
LEFT JOIN GLTransactionTypes M2 on M1.GLTransactionTypeId = M2.Id

GO
