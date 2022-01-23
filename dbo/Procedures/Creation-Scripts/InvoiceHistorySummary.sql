SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InvoiceHistorySummary]
(
@CustomerNumber NVARCHAR(40) = NULL,
@CustomerName NVARCHAR(MAX) = NULL,
@InvoiceStatus NVARCHAR(20) = NULL,
@PaymentStatus NVARCHAR(20) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LineOfBusiness NVARCHAR(MAX) = NULL,
@Currency NVARCHAR(10) = NULL,
@AsOfDate DATETIME = NULL
)
AS
SET NOCOUNT ON
SELECT
le.LegalEntityNumber LegalEntityNumber,
ri.InvoiceAmount_Currency InvoiceAmount_Currency,
p.PartyNumber PartyNumber,
ri.Number InvoiceNumber,
p.PartyName PartyName,
bt.Name BillToName,
ri.DueDate InvoiceDueDate,
DATEDIFF(dd,ri.DueDate,@AsOfDate) DaysPastDue,
ri.InvoiceAmount_Amount,
ri.InvoiceTaxAmount_Amount,
ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount TotalDue,
ri.Id InvoiceId,
SUM(rd.Amount_Amount) TotalAmount,
SUM(rd.EffectiveBalance_Amount) TotalEffectiveBalance,
CAST(0.0 as decimal(16,2)) TotalTaxAmount,
CAST(0.0 as decimal(16,2)) TotalEffectiveTaxBalance,
ri.Balance_Amount,
ri.TaxBalance_Amount,
ri.EffectiveBalance_Amount,
ri.EffectiveTaxBalance_Amount
INTO #ReceivableInvoiceDetails
FROM ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.Id AND ri.IsActive = 1 AND ri.IsDummy = 0 AND rid.IsActive = 1
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id AND rd.IsActive = 1
INNER JOIN dbo.Parties p ON ri.CustomerId = p.Id
INNER JOIN dbo.BillToes bt ON ri.BillToId = bt.Id
INNER JOIN dbo.LegalEntities le ON le.Id = ri.LegalEntityId
WHERE (@AsOfDate IS NULL OR @AsOfDate >= ri.DueDate)
AND (@CustomerNumber IS NULL OR p.PartyNumber = @CustomerNumber)
AND (@CustomerName IS NULL OR p.PartyName = @CustomerName)
AND (@LegalEntityNumber IS NULL OR le.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@Currency IS NULL OR le.CurrencyCode = @Currency)
GROUP BY ri.Id,
le.LegalEntityNumber ,
ri.InvoiceAmount_Currency ,
p.PartyNumber ,
ri.Number ,
p.PartyName ,
bt.Name ,
ri.DueDate ,
ri.InvoiceAmount_Amount,
ri.InvoiceTaxAmount_Amount,
ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount ,
ri.Id ,
ri.Balance_Amount,
ri.TaxBalance_Amount,
ri.EffectiveBalance_Amount,
ri.EffectiveTaxBalance_Amount
UPDATE #ReceivableInvoiceDetails
SET TotalTaxAmount = TaxInfo.Amount_Amount,
TotalEffectiveTaxBalance = TaxInfo.EffectiveBalance_Amount
FROM #ReceivableInvoiceDetails
JOIN(SELECT ri.InvoiceId,SUM(rtd.Amount_Amount) Amount_Amount, SUM(rtd.EffectiveBalance_Amount) EffectiveBalance_Amount
FROM #ReceivableInvoiceDetails ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.InvoiceId AND rid.IsActive = 1
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id AND rd.IsActive = 1
INNER JOIN ReceivableTaxDetails rtd ON rd.Id = rtd.ReceivableDetailId AND rtd.IsActive = 1 AND rtd.IsActive = 1
JOIN ReceivableTaxes rt ON rtd.ReceivableTaxId = rt.Id AND rt.IsActive = 1
GROUP BY ri.InvoiceId
)
AS TaxInfo ON #ReceivableInvoiceDetails.InvoiceId = TaxInfo.InvoiceId
SELECT * INTO #InvoiceHistorySummary
FROM
(SELECT
DISTINCT
ri.LegalEntityNumber AS 'LegalEntity #',
ri.InvoiceAmount_Currency AS 'Currency',
ri.PartyNumber AS 'Account #',
ri.InvoiceNumber AS 'Invoice #',
ri.PartyName  AS 'Customer',
ri.BillToName AS 'Bill To',
ri.InvoiceDueDate AS 'Due Date',
ri.DaysPastDue AS 'Days Past Due',
CAST(1 AS BIT) IsActive,
ri.TotalDue AS 'Amount Due',
(ri.TotalAmount + ri.TotalTaxAmount)-(ri.TotalEffectiveBalance + ri.TotalEffectiveTaxBalance) As 'Amount Paid',
ri.EffectiveBalance_Amount + ri.EffectiveTaxBalance_Amount AS 'Balance',
CASE
WHEN ri.Balance_Amount + ri.TaxBalance_Amount = 0 THEN 'Paid'
WHEN (ri.EffectiveBalance_Amount + ri.EffectiveTaxBalance_Amount > 0) AND (ri.TotalAmount + ri.TotalTaxAmount)-(ri.TotalEffectiveBalance + ri.TotalEffectiveTaxBalance) ! = 0 THEN 'PartiallyPaid'
ELSE 'Unpaid'
END
AS 'Payment Status',
'Active'AS 'Invoice Status', -- As only active records are fetched we are removing the case
r.Number AS 'Receipt#',
r.ReceivedDate,
rb.Id AS 'ReceiptBatchId',
rid.ReceivableDetailId,
(rard.AmountApplied_Amount+rard.TaxApplied_Amount) AS 'Receipt Applied',
rt.ReceiptTypeName,
r.PostDate,
CASE
WHEN r.Status = 'Reversed' THEN 'Yes'
WHEN r.Status != 'Reversed' THEN 'No'
ELSE ''
END
AS 'Receipt Reversed',
rid.EntityType,
rid.EntityId,
lb.Name,
ri.TotalAmount + ri.TotalTaxAmount AS 'Receivable Amount'
FROM #ReceivableInvoiceDetails ri
INNER JOIN dbo.ReceivableInvoiceDetails rid WITH(NOLOCK) ON rid.ReceivableInvoiceId = ri.InvoiceId
INNER JOIN dbo.ReceivableDetails rd With(NOLOCK) ON rd.Id = rid.ReceivableDetailId
INNER JOIN dbo.Receivables r2 ON rd.ReceivableId = r2.Id
LEFT JOIN dbo.Contracts c ON c.Id = r2.EntityId AND r2.EntityType = 'CT'
LEFT JOIN dbo.Sundries s ON s.ReceivableId = r2.Id
LEFT JOIN dbo.SecurityDeposits sd ON sd.ReceivableId = r2.Id
LEFT JOIN dbo.SundryRecurringPaymentSchedules srps ON srps.ReceivableId = r2.Id
LEFT JOIN dbo.SundryRecurrings sr ON srps.SundryRecurringId = sr.Id
LEFT JOIN dbo.LineofBusinesses lb ON Lb.Id = COALESCE(c.LineofBusinessId,s.LineofBusinessId,sd.LineofBusinessId,sr.LineofBusinessId)
LEFT JOIN dbo.ReceiptApplicationReceivableDetails rard WITH(NOLOCK) ON rard.ReceivableDetailId = rd.Id AND rard.IsActive = 1
LEFT JOIN dbo.ReceiptApplications ra WITH(NOLOCK) ON ra.Id = rard.ReceiptApplicationId
LEFT JOIN dbo.Receipts r ON r.Id = ra.ReceiptId AND r.Status IN ('Posted','Completed','Reversed')
LEFT JOIN dbo.ReceiptTypes rt ON rt.Id = r.TypeId AND rt.IsActive = 1
LEFT JOIN dbo.ReceiptBatches rb ON rb.Id = r.ReceiptBatchId
WHERE (@LineOfBusiness IS NULL OR lb.Name = @LineOfBusiness)
UNION
SELECT
DISTINCT
ri.LegalEntityNumber AS 'LegalEntity #',
ri.InvoiceAmount_Currency AS 'Currency',
ri.PartyNumber AS 'Account #',
ri.InvoiceNumber AS 'Invoice #',
ri.PartyName  AS 'Customer',
ri.BillToName AS 'Bill To',
ri.InvoiceDueDate AS 'Due Date',
ri.DaysPastDue AS 'Days Past Due',
CAST(1 AS BIT) IsActive,
ri.TotalDue AS 'Amount Due',
(ri.TotalAmount + ri.TotalTaxAmount)-(ri.TotalEffectiveBalance + ri.TotalEffectiveTaxBalance) As 'Amount Paid',
ri.EffectiveBalance_Amount + ri.EffectiveTaxBalance_Amount AS 'Balance',
CASE
WHEN ri.Balance_Amount + ri.TaxBalance_Amount = 0 THEN 'Paid'
WHEN (ri.EffectiveBalance_Amount + ri.EffectiveTaxBalance_Amount > 0) AND (ri.TotalAmount + ri.TotalTaxAmount)-(ri.TotalEffectiveBalance + ri.TotalEffectiveTaxBalance) ! = 0 THEN 'PartiallyPaid'
ELSE 'Unpaid'
END
AS 'Payment Status',
'Active'AS 'Invoice Status', -- As only active records are fetched we are removing the case
r.Number AS 'Receipt#',
r.ReceivedDate,
rb.Id AS 'ReceiptBatchId',
rid.ReceivableDetailId,
dh.AmountPosted_Amount AS 'Receipt Applied',
rt.ReceiptTypeName,
r.PostDate,
CASE
WHEN r.Status = 'Reversed' THEN 'Yes'
WHEN r.Status != 'Reversed' THEN 'No'
ELSE ''
END
AS 'Receipt Reversed',
rid.EntityType,
rid.EntityId,
lb.Name,
ri.TotalAmount + ri.TotalTaxAmount AS 'Receivable Amount'
FROM #ReceivableInvoiceDetails ri
INNER JOIN dbo.ReceivableInvoiceDetails rid With(NOLOCK) ON rid.ReceivableInvoiceId = ri.InvoiceId
INNER JOIN dbo.ReceivableDetails rd WITH(NOLOCK) ON rd.Id = rid.ReceivableDetailId
INNER JOIN dbo.Receivables r2 ON rd.ReceivableId = r2.Id
LEFT JOIN dbo.Contracts c ON c.Id = r2.EntityId AND r2.EntityType = 'CT'
LEFT JOIN dbo.Sundries s ON s.ReceivableId = r2.Id
LEFT JOIN dbo.SecurityDeposits sd ON sd.ReceivableId = r2.Id
LEFT JOIN dbo.SundryRecurringPaymentSchedules srps ON srps.ReceivableId = r2.Id
LEFT JOIN dbo.SundryRecurrings sr ON srps.SundryRecurringId = sr.Id
LEFT JOIN dbo.LineofBusinesses lb ON Lb.Id = COALESCE(c.LineofBusinessId,s.LineofBusinessId,sd.LineofBusinessId,sr.LineofBusinessId)
LEFT JOIN dbo.DSLReceiptHistories dh WITH(NOLOCK) ON dh.ReceivableDetailId = rid.ReceivableDetailId
LEFT JOIN dbo.Receipts r ON r.Id = dh.ReceiptId AND r.Status IN ('Posted','Completed','Reversed')
LEFT JOIN dbo.ReceiptTypes rt ON rt.Id = r.TypeId AND rt.IsActive = 1
LEFT JOIN dbo.ReceiptBatches rb ON rb.Id = r.ReceiptBatchId
WHERE (@LineOfBusiness IS NULL OR lb.Name = @LineOfBusiness)
)AS FinalResult
SELECT ROW_NUMBER()Over(PARTITION BY t.[LegalEntity #], t.Currency, t.[Account #], t.[Invoice #], t.Customer, t.[Bill To], t.[Due Date], t.[Days Past Due], t.IsActive, t.[Invoice Status], t.[Payment Status] ORDER BY t.[LegalEntity #], t.Currency, t.[Account #], t.[Invoice #], t.Customer, t.[Bill To], t.[Due Date], t.[Days Past Due], t.IsActive,t.Receipt# desc,t.[Receipt Applied] desc, t.[Amount Due], t.[Amount Paid], t.Balance, t.[Invoice Status], t.[Payment Status]) AS [RowNumber]
,t.* INTO #FinalResult
FROM dbo.#InvoiceHistorySummary t
WHERE (@InvoiceStatus = '_' OR t.[Invoice Status] = @InvoiceStatus)
AND (@PaymentStatus = '_' OR t.[Payment Status] = @PaymentStatus)
DELETE FROM #FinalResult WHERE Receipt# IS NULL AND RowNumber != 1
SELECT * FROM #FinalResult
DROP TABLE dbo.#InvoiceHistorySummary
DROP TABLE #ReceivableInvoiceDetails
DROP TABLE #FinalResult

GO
