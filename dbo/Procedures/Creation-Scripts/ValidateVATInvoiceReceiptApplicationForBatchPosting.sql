SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ValidateVATInvoiceReceiptApplicationForBatchPosting]
(  
	@ReceiptBatchIds ReceiptBatchIds READONLY,
	@InvoiceTaxBalanceNotCleared_ReceiptBatchReadyForPosting NVARCHAR(MAX),
	@ReceiptStatus_ReadyForPosting NVARCHAR(20),
	@ErrorMessage NVARCHAR(MAX) OUT
)  
AS  
BEGIN  
	
	CREATE TABLE #ValidateVATInvoiceApplication
	(
	InvoiceNumber NVARCHAR(50),
	ReceivableInvoiceId BIGINT,
	ReceiptAmount DECIMAL(16,2),
	ReceivableDetailId BIGINT,
	GroupNumber BIGINT,
	ReceiptNumber NVARCHAR(50) NULL,
	IsValid BIT DEFAULT 1,
	ErrorMessage NVARCHAR(500) NULL,
	AmountApplied DECIMAL(16,2),
	TaxApplied DECIMAL(16,2)
	)

	--drop table #ValidateVATInvoiceApplication
	INSERT INTO #ValidateVATInvoiceApplication (InvoiceNumber, ReceivableInvoiceId,ReceiptAmount,ReceivableDetailId,GroupNumber,ReceiptNumber,AmountApplied,TaxApplied)
	SELECT RI.Number AS InvoiceNumber,RI.Id AS ReceivableInvoiceId,(R.ReceiptAmount_Amount - R.Balance_Amount) AS ReceiptAmount,RARD.ReceivableDetailId,R.Id AS GroupNumber,R.Number, RARD.AmountApplied_Amount AS AmountAppliedTowardsReceivables, RARD.TaxApplied_Amount AS AmountAppliedTowardsTaxes
	FROM ReceiptApplicationReceivableDetails rard
	join ReceiptApplications ra ON rard.ReceiptApplicationId = ra.id
	join Receipts r ON ra.ReceiptId = r.Id
	join ReceivableInvoiceDetails rid ON rid.ReceivableDetailId = rard.ReceivableDetailId
	join ReceivableInvoices ri ON rid.ReceivableInvoiceId = ri.Id
	join @ReceiptBatchIds RBIds ON r.ReceiptBatchId = RBIds.Id
	WHERE r.Status=@ReceiptStatus_ReadyForPosting AND RI.ReceivableTaxType = 'VAT'

	CREATE TABLE #InvoiceApplications
	(
		ReceivableInvoiceId BIGINT,
		TotalInvoiceAmountApplied DECIMAL(16,2),
		TotalTaxAmountApplied DECIMAL(16,2),
		InvoiceBalance DECIMAL(16,2),
		InvoiceTaxBalance DECIMAL(16,2),
		IsValid BIT DEFAULT 1
	)

	INSERT INTO #InvoiceApplications
	SELECT ReceivableInvoiceId,SUM(AmountApplied) TotalInvoiceAmountApplied,SUM(TaxApplied) TotalTaxAmountApplied , RI.Balance_Amount InvoiceBalance,RI.TaxBalance_Amount InvoiceTaxBalance,1 IsValid
	FROM #ValidateVATInvoiceApplication VIA
	JOIN ReceivableInvoices RI ON RI.Id=VIA.ReceivableInvoiceId
	GROUP BY ReceivableInvoiceId,RI.Balance_Amount,RI.TaxBalance_Amount

	UPDATE #InvoiceApplications
		SET IsValid = 0
	WHERE InvoiceTaxBalance != TotalTaxAmountApplied

	UPDATE VIA
		SET IsValid=0
	FROM #ValidateVATInvoiceApplication VIA
	JOIN #InvoiceApplications IA ON VIA.ReceivableInvoiceId = IA.ReceivableInvoiceId
	WHERE IA.IsValid = 0 AND VIA.AmountApplied <> 0

	UPDATE RE
	SET IsValid=0
	FROM Receipts_Extract RE
	JOIN #ValidateVATInvoiceApplication VIA ON RE.ReceiptId = VIA.GroupNumber
	WHERE VIA.IsValid=0

	DECLARE @InvalidReceiptNumbers NVARCHAR(MAX)

	SELECT @InvalidReceiptNumbers =	ISNULL(@InvalidReceiptNumbers + ', ' + ReceiptNumber, ReceiptNumber)
	FROM #ValidateVATInvoiceApplication
	WHERE ReceiptNumber IS NOT NULL
	AND IsValid=0
	GROUP BY ReceiptNumber

	SELECT @ErrorMessage=REPLACE(@InvoiceTaxBalanceNotCleared_ReceiptBatchReadyForPosting,'@ReceiptNumbers',@InvalidReceiptNumbers)
	
	DROP TABLE #ValidateVATInvoiceApplication

END

GO
