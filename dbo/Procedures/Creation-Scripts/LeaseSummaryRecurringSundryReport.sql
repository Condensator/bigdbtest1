SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LeaseSummaryRecurringSundryReport]
(
@SequenceNumber  NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT
T.ContractId,
ReceivableCodes.Name,
T.InvoiceAmount
FROM
(
SELECT
ROW_NUMBER() OVER(PARTITION BY SundryRecurrings.Contractid,SundryRecurrings.Id ORDER BY isnull(ReceivableInvoices.DueDate,Receivables.DueDate)DESC) [RWNo],
SundryRecurrings.Contractid,
Receivables.ReceivableCodeId,
ReceivableInvoiceDetails.Balance_Amount AS InvoiceAmount
FROM
SundryRecurrings
INNER JOIN Contracts
ON SundryRecurrings.ContractID = Contracts.ID
AND Contracts.SequenceNumber = @SequenceNumber
INNER JOIN SundryRecurringPaymentSchedules
ON  SundryRecurrings.Id=SundryRecurringPaymentSchedules.SundryRecurringId
INNER JOIN Receivables
ON Receivables.id=SundryRecurringPaymentSchedules.Receivableid AND Receivables.IsActive=1
INNER JOIN ReceivableDetails
ON ReceivableDetails.ReceivableId=Receivables.id AND ReceivableDetails.IsActive=1  AND ReceivableDetails.BilledStatus='Invoiced'
LEFT JOIN ReceivableInvoiceDetails
ON ReceivableInvoiceDetails.ReceivableDetailId=ReceivableDetails.ID
LEFT JOIN ReceivableInvoices
ON ReceivableInvoices.id=ReceivableInvoiceDetails.ReceivableInvoiceId
WHERE
ISNULL(ReceivableInvoices.DueDate,Receivables.DueDate) <= GETDATE()
)T
INNER JOIN ReceivableCodes
ON ReceivableCodes.id = T.ReceivableCodeId
AND ReceivableCodes.IsActive = 1
WHERE
T.RWNo=1
END

GO
