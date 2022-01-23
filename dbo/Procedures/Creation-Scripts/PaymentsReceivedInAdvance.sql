SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PaymentsReceivedInAdvance]
@AsOfDate DATE,
@SequenceNumber NVARCHAR(100) = NULL,
@PartyNumber NVARCHAR(100) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL
AS
BEGIN
SET NOCOUNT ON
SELECT ReceivableId, PostDate INTO #ReceivableGLJournalsToExclude FROM ReceivableGLJournals
EXCEPT
SELECT [RGLJ].ReceivableId, [RGLJ].PostDate FROM ReceivableGLJournals [RGLJ]
JOIN ReceivableGLJournals [RRGLJ] ON [RGLJ].Id = [RRGLJ].ReversalGLJournalOfId
SELECT
Receipts.Id [ReceiptId],
Receipts.Number [ReceiptNumber],
CurrencyCodes.ISO [Currency],
ReceiptTypeName [ReceiptType],
''[AccountNumber],--Encryption Change
Contracts.ContractType [ContractType],
Contracts.SequenceNumber [SequenceNumber],
ReceivableTypes.Name [ReceivableType],
Receipts.ReceivedDate [PaidDate],
#ReceivableGLJournalsToExclude.PostDate [PostDate],
Receivables.TotalAmount_Amount [AmountReceivable],
CASE WHEN ReceivableTaxes.Amount_Amount IS NULL THEN 0.0 ELSE ReceivableTaxes.Amount_Amount END [TaxReceivable],
Receivables.TotalAmount_Amount + CASE WHEN ReceivableTaxes.Amount_Amount IS NULL THEN 0.0 ELSE ReceivableTaxes.Amount_Amount END [TotalReceivable],
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) [AmountPosted],
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) [TaxPosted],
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) + SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) [TotalPosted],
Receivables.IsGLPosted [IsReceivableAmountGLPosted],
ReceivableTaxes.IsGLPosted [IsReceivableTaxGLPosted],
MIN(CONVERT(INT,ReceiptApplicationReceivableDetails.IsGLPosted)) [IsReceiptAmountGLPosted],
MIN(CONVERT(INT,ReceiptApplicationReceivableDetails.IsTaxGLPosted)) [IsReceiptTaxGLPosted],
Parties.PartyNumber [PartyNumber],
LegalEntities.LegalEntityNumber [LegalEntityNumber],
GLTemplates.Name [GLTemplate],
Receivables.Id [ReceivableId]
INTO #PaymentsReceivedInAdvance
FROM Receipts
INNER JOIN Currencies ON Receipts.CurrencyId = Currencies.Id
INNER JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
INNER JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id AND ReceiptTypes.IsActive = 1
INNER JOIN BankAccounts ON Receipts.BankAccountId = BankAccounts.Id AND BankAccounts.IsActive = 1
INNER JOIN ReceiptApplications ON Receipts.Id = ReceiptApplications.ReceiptId
INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND ReceiptApplicationReceivableDetails.IsActive = 1
INNER JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive = 1
INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive = 1
INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id AND ReceivableCodes.IsActive = 1
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
INNER JOIN Parties ON Receivables.CustomerId = Parties.Id
INNER JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
INNER JOIN GLTemplates ON ReceivableCodes.GLTemplateId = GLTemplates.Id
LEFT JOIN ReceivableTaxes ON Receivables.Id = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive = 1
LEFT JOIN #ReceivableGLJournalsToExclude ON Receivables.Id = #ReceivableGLJournalsToExclude.ReceivableId
LEFT JOIN Contracts ON Receivables.EntityId = Contracts.Id AND Receivables.EntityType = 'CT'
WHERE Receipts.Status = 'Posted'
GROUP BY
Receipts.Id,
Receipts.Number,
CurrencyCodes.ISO,
Receipts.Status,
ReceiptTypes.Id,
ReceiptTypes.ReceiptTypeName,
--BankAccounts.AccountNumber, --Encryption Change
Receivables.Id,
Contracts.ContractType,
Contracts.SequenceNumber,
ReceivableTypes.Name,
Receipts.ReceivedDate,
#ReceivableGLJournalsToExclude.PostDate,
Receivables.TotalAmount_Amount,
ReceivableTaxes.Amount_Amount,
Receivables.IsGLPosted,
ReceivableTaxes.IsGLPosted,
Parties.PartyNumber,
LegalEntities.LegalEntityNumber,
GLTemplates.Name
SELECT
GLTemplate,
Currency,
ReceiptId,
ReceiptNumber,
ReceiptType,
AccountNumber,
ContractType,
SequenceNumber,
ReceivableType,
PaidDate,
PostDate,
AmountReceivable,
TaxReceivable,
TotalReceivable,
AmountPosted,
TaxPosted,
TotalPosted,
PartyNumber,
LegalEntityNumber,
ReceivableId
FROM #PaymentsReceivedInAdvance
WHERE TotalPosted != 0.0
AND (PaidDate < @AsOfDate AND (PostDate IS NULL OR PostDate > PaidDate))
AND (@SequenceNumber IS NULL OR SequenceNumber = @SequenceNumber)
AND (@PartyNumber IS NULL OR PartyNumber = @PartyNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
UNION
SELECT
GLTemplate,
Currency,
ReceiptId,
ReceiptNumber,
ReceiptType,
AccountNumber,
ContractType,
SequenceNumber,
ReceivableType,
PaidDate,
PostDate,
AmountReceivable,
TaxReceivable,
TotalReceivable,
AmountPosted,
TaxPosted,
TotalPosted,
PartyNumber,
LegalEntityNumber,
ReceivableId
FROM #PaymentsReceivedInAdvance
WHERE TotalPosted != 0.0
AND (PaidDate < @AsOfDate AND PostDate IS NOT NULL AND PostDate = PaidDate AND ((IsReceiptAmountGLPosted = 0 AND IsReceivableAmountGLPosted = 1) OR (IsReceiptTaxGLPosted = 0 AND IsReceivableTaxGLPosted = 1)))
AND (@SequenceNumber IS NULL OR SequenceNumber = @SequenceNumber)
AND (@PartyNumber IS NULL OR PartyNumber = @PartyNumber)
AND (@LegalEntityNumber IS NULL OR LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
DROP TABLE #ReceivableGLJournalsToExclude
DROP TABLE #PaymentsReceivedInAdvance
SET NOCOUNT OFF
END

GO
