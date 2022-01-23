SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceStatement]
(
@CustomerNumber NVARCHAR(40) = NULL,
@CustomerName NVARCHAR(MAX) = NULL,
@ContractSequenceNumber NVARCHAR(40) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@InvoiceNumber NVARCHAR(40) = NULL,
@CurrencyCode NVARCHAR(3) = NULL,
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
P.PartyName,
P.PartyNumber 'AccountNumber',
Con.SequenceNumber 'SequenceNumber',
--BA.AccountNumber,
--Convert(VARCHAR(10),RI.DueDate,101) 'DueDate',
RI.DueDate 'DueDate',
InvoiceNumber = RI.Number,
ReceivableTypeName = rtlc.Name,
LE.CurrencyCode,
OriginalReceivableAmount = Sum(RID.InvoiceAmount_Amount),
OriginalTaxAmount = Sum(RID.InvoiceTaxAmount_Amount),
TotalReceivableDue = Sum(RID.InvoiceAmount_Amount + RID.InvoiceTaxAmount_Amount),
InvoiceBalance = Sum(RID.Balance_Amount + RID.TaxBalance_Amount),
ReceivableAmount = Sum(RD.Amount_Amount + ISNULL(ReceivableTaxAmount.TaxAmount, 0.00))
FROM ReceivableInvoices RI
INNER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN dbo.ReceivableCategories rc2 ON rc2.Id = rc.ReceivableCategoryId
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN dbo.ReceivableTypeLabelConfigs rtlc ON rtlc.ReceivableCategoryId = rc2.Id AND rtlc.ReceivableTypeId = rt.Id AND rtlc.IsDefault = 1 AND rtlc.IsActive = 1
INNER JOIN Parties P ON RI.CustomerId = P.Id
INNER JOIN LegalEntities LE ON RI.LegalEntityId = LE.Id
INNER JOIN Currencies C ON RI.CurrencyId = C.Id
INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
LEFT JOIN Contracts Con ON R.EntityId = Con.Id AND R.EntityType = 'CT'
--LEFT JOIN PartyBankAccounts PBA ON PBA.PartyId = P.Id
--LEFT JOIN BankAccounts BA ON PBA.BankAccountId = BA.Id
LEFT JOIN (
SELECT RID.ReceivableDetailId, SUM(RTD.Amount_Amount) TaxAmount
FROM ReceivableInvoices RI
INNER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
INNER JOIN Parties P ON RI.CustomerId = P.Id
INNER JOIN LegalEntities LE ON RI.LegalEntityId = LE.Id
INNER JOIN Currencies C ON RI.CurrencyId = C.Id
INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
LEFT JOIN Contracts Con ON RID.EntityId = Con.Id AND RID.EntityType = 'CT'
INNER JOIN ReceivableTaxDetails RTD ON RID.ReceivableDetailId = RTD.ReceivableDetailId
INNER JOIN ReceivableTaxes RT ON RTD.ReceivableTaxId = RT.Id
WHERE RID.IsActive = 1 AND RTD.IsActive = 1 AND RT.IsActive = 1
GROUP BY RID.ReceivableDetailId
) AS ReceivableTaxAmount ON ReceivableTaxAmount.ReceivableDetailId = RD.Id
WHERE
RI.IsActive = 1 AND RID.IsActive=1 AND RD.IsActive=1  AND RI.IsDummy = 0 AND R.IsDummy = 0
AND (RI.DueDate >= @FromDate AND RI.DueDate <= @ToDate)
AND (@CustomerNumber IS NULL OR P.PartyNumber = @CustomerNumber)
AND (@CustomerName IS NULL OR P.PartyName = @CustomerName)
AND (@LegalEntityNumber IS NULL OR LE.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@InvoiceNumber IS NULL OR RI.Number = @InvoiceNumber)
AND (@CurrencyCode IS NULL OR CC.ISO = @CurrencyCode)
AND (@ContractSequenceNumber IS NULL OR CON.SequenceNumber = @ContractSequenceNumber)
group BY P.PartyName,P.PartyNumber,Con.SequenceNumber,RI.Number,RI.DueDate,rtlc.Name,LE.CurrencyCode
ORDER BY LE.CurrencyCode,P.PartyName,RI.Number,RI.DueDate,rtlc.Name

GO
