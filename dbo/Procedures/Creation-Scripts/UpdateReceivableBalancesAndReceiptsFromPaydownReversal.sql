SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateReceivableBalancesAndReceiptsFromPaydownReversal]
(
	@ReceiptId BIGINT,	

	@UpdatedById BIGINT,

	@UpdatedTime DATETIMEOFFSET
)

AS

BEGIN

SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #ReceivableDetailsFromPaydown 
(
ReceivableId BIGINT,
ReceivableDetailId BIGINT,
InvoiceId BIGINT,
AmountPosted DECIMAL(16,2)
)


INSERT INTO #ReceivableDetailsFromPaydown
(ReceivableId,
ReceivableDetailId,
InvoiceId,
AmountPosted)

SELECT 
R.Id,
RD.Id,
dslRH.InvoiceId,
dslRH.AmountPosted_Amount

FROM DSLReceiptHistories dslRH 
INNER JOIN Receipts RC on dslRH.ReceiptId = RC.Id
INNER JOIN ReceivableDetails RD on dslRH.ReceivableDetailId = RD.Id
INNER JOIN Receivables R on RD.ReceivableId = R.Id
WHERE Rc.Id = @ReceiptId;


UPDATE Receivables

SET TotalBalance_Amount = TotalBalance_Amount + RD.AmountPosted,
TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount + RD.AmountPosted,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime

FROM #ReceivableDetailsFromPaydown RD INNER JOIN Receivables R on RD.ReceivableId = R.Id

UPDATE ReceivableDetails

SET Balance_Amount = Balance_Amount + RD.AmountPosted,
EffectiveBalance_Amount = EffectiveBalance_Amount + RD.AmountPosted,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
LeaseComponentBalance_Amount = Balance_Amount + RD.AmountPosted
FROM #ReceivableDetailsFromPaydown RD INNER JOIN ReceivableDetails R on RD.ReceivableDetailId = R.Id

;WITH CTE_InvoiceDetails
AS
(
SELECT InvoiceId = RD.InvoiceId, AmountPosted = SUM(RD.AmountPosted) FROM #ReceivableDetailsFromPaydown RD GROUP By RD.InvoiceId
)

UPDATE ReceivableInvoices
       SET  Balance_Amount = Balance_Amount + CTE.AmountPosted,
			EffectiveBalance_Amount = EffectiveBalance_Amount + CTE.AmountPosted,
			UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime
FROM CTE_InvoiceDetails CTE INNER JOIN ReceivableInvoices RI on CTE.InvoiceId = RI.Id;

UPDATE ReceivableInvoiceDetails

SET Balance_Amount = Balance_Amount + RD.AmountPosted,
EffectiveBalance_Amount = EffectiveBalance_Amount + RD.AmountPosted,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime

FROM #ReceivableDetailsFromPaydown RD INNER JOIN ReceivableInvoiceDetails RID on RD.InvoiceId = RID.ReceivableInvoiceId AND RD.ReceivableDetailId = RID.ReceivableDetailId

UPDATE Receipts

SET Status='Reversed',
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime

WHERE Receipts.Id = @ReceiptId

UPDATE DSLReceiptHistories 

SET IsActive = 0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime

WHERE DSLReceiptHistories.ReceiptId = @ReceiptId;

UPDATE ReceiptPostByDSLDetails

SET IsActive = 0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime

WHERE ReceiptPostByDSLDetails.ReceiptId = @ReceiptId;

DROP Table #ReceivableDetailsFromPaydown

END

GO
