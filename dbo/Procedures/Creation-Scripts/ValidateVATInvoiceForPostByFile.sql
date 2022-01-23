SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ValidateVATInvoiceForPostByFile]
(  
	@ValidateVATInvoiceForPostByFileTable	ValidateVATInvoiceForPostByFileTable READONLY,
	@VATInvoiceNotFullyCleared						NVARCHAR(500),
	@VatTaxOutstandingBalanceNotCompletelyApplied	NVARCHAR(200),
	@InvoiceTaxBalanceNotClearedForReceiptBatch		NVARCHAR(500),
	@JobStepInstanceId								BIGINT,
	@IsPostingAllowed								BIT,
	@ReceiptBatchId									BIGINT NULL
)  
AS  
BEGIN  
	
	CREATE TABLE #UpdatedReceiptExtract
	(
		JobStepInstanceId BIGINT,
		GroupNumber		  BIGINT
	)

	SELECT
		VIP.ReceivableInvoiceId,
		VIP.InvoiceNumber,
		RI.Balance_Amount	AS RIBalanceAmount,
		RI.TaxBalance_Amount AS	RITaxBalanceAmount,
		VIP.ReceiptAmount,
		VIP.GroupNumber,
		SUM(RID.Balance_Amount) AS RIDBalanceAmount,
		SUM(RID.TaxBalance_Amount) AS RIDTaxBalanceAmount,
		SUM(RID.EffectiveBalance_Amount) AS RIDEffectiveBalanceAmount,
		SUM(RID.EffectiveTaxBalance_Amount) AS RIDEffectiveTaxBalanceAmount, 
		SUM(VIP.ReceiptAmount) OVER (PARTITION BY VIP.ReceivableInvoiceId ORDER BY VIP.GroupNumber DESC) AS RunningReceiptAmount
	INTO #VATReceivableInvoices
	FROM @ValidateVATInvoiceForPostByFileTable VIP
	JOIN ReceivableInvoices RI ON VIP.ReceivableInvoiceId = RI.Id
	JOIN ReceivableInvoiceDetails RID ON VIP.ReceivableInvoiceId = RID.ReceivableInvoiceId
	AND VIP.ReceivableDetailId = RID.ReceivableDetailId
	GROUP BY 
		VIP.ReceivableInvoiceId,
		VIP.InvoiceNumber,
		VIP.ReceiptAmount,
		RI.Balance_Amount,
		RI.TaxBalance_Amount,
		VIP.GroupNumber
	;

	--Receipt needs to be imported with all invoice receivable where the receivable amount is getting cleared
	
	UPDATE RPB
		SET 
		--SELECT RPB.RECEIPTAMOUNT,
		HasError = 1, 
		ErrorMessage = CONCAT(ISNULL(RPB.ErrorMessage, ''), REPLACE(@VATInvoiceNotFullyCleared, '@invalidInvoices', RPB.InvoiceNumber))
	OUTPUT deleted.JobStepInstanceId, deleted.GroupNumber INTO #UpdatedReceiptExtract
	FROM ReceiptPostByFileExcel_Extract RPB
	JOIN #VATReceivableInvoices VRI ON RPB.InvoiceNumber = VRI.InvoiceNumber
	AND RPB.JobStepInstanceId = @JobStepInstanceId AND RPB.GroupNumber = VRI.GroupNumber
	WHERE RPB.ErrorMessage IS NULL
	AND VRI.RITaxBalanceAmount <> 0
	AND VRI.RITaxBalanceAmount <> VRI.RIDTaxBalanceAmount
	AND VRI.ReceiptAmount > VRI.RIDTaxBalanceAmount

	UPDATE RD
		SET RD.IsValid = 0
	FROM Receipts_Extract RD INNER JOIN #UpdatedReceiptExtract R 
	ON R.GroupNumber = RD.DumpId AND RD.JobStepInstanceId = R.JobStepInstanceId

	--Receipt with pending state for a receivable

	IF(@IsPostingAllowed = 1)
	BEGIN
		IF(@ReceiptBatchId IS NULL)
		BEGIN
				UPDATE RPB
					SET 
					--SELECT RPB.RECEIPTAMOUNT, VRI.RITaxBalanceAmount, VRI.RIDEffectiveTaxBalanceAmount, VRI.ReceiptAmount,
					HasError = 1, 
					ErrorMessage = REPLACE(@VatTaxOutstandingBalanceNotCompletelyApplied, '@InvoiceNumber', RPB.InvoiceNumber)
				OUTPUT deleted.JobStepInstanceId, deleted.GroupNumber INTO #UpdatedReceiptExtract
				FROM ReceiptPostByFileExcel_Extract RPB
				JOIN #VATReceivableInvoices VRI ON RPB.InvoiceNumber = VRI.InvoiceNumber
				AND RPB.JobStepInstanceId = @JobStepInstanceId AND RPB.GroupNumber = VRI.GroupNumber
				WHERE RPB.ErrorMessage IS NULL AND VRI.RIDEffectiveTaxBalanceAmount <> 0.00
				AND VRI.RITaxBalanceAmount > VRI.RIDEffectiveTaxBalanceAmount
				AND (VRI.ReceiptAmount - VRI.RIDEffectiveTaxBalanceAmount) > 0
				;
		END

		IF(@ReceiptBatchId IS NOT NULL)
		BEGIN

			WITH CTE_TaxBalanceNotCleared AS
			(
				SELECT 
					RPB.Id, RPB.ComputedReceivableInvoiceId, RPB.JobStepInstanceId
				FROM ReceiptPostByFileExcel_Extract RPB
				JOIN #VATReceivableInvoices VRI ON RPB.InvoiceNumber = VRI.InvoiceNumber
				AND RPB.JobStepInstanceId = @JobStepInstanceId AND RPB.GroupNumber = VRI.GroupNumber
				WHERE RPB.ErrorMessage IS NULL AND VRI.RIDEffectiveTaxBalanceAmount <> 0.00
				AND VRI.RITaxBalanceAmount > VRI.RIDEffectiveTaxBalanceAmount
				AND (VRI.ReceiptAmount - VRI.RIDEffectiveTaxBalanceAmount) > 0
			)
			SELECT
				DISTINCT TB.Id, TB.ComputedReceivableInvoiceId, TB.JobStepInstanceId, R.Number ReceiptNumber
			INTO #RBFTaxBalanceNotCleared
			FROM CTE_TaxBalanceNotCleared TB
			INNER JOIN ReceiptApplicationReceivableDetails RARD ON TB.ComputedReceivableInvoiceId = RARD.ReceivableInvoiceId
			INNER JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
			INNER JOIN Receipts R ON RA.ReceiptId = R.Id
			WHERE R.Status IN ('Pending', 'Submitted') AND R.ReceiptClassification IN ('Cash', 'NonCash')
			;

			WITH CTE_ReceiptCSV AS
			(
				SELECT 
					T2.ComputedReceivableInvoiceId, T2.JobStepInstanceId, T2.Id,
					STUFF((SELECT ',' + CAST(T1.ReceiptNumber AS VARCHAR) FROM #RBFTaxBalanceNotCleared T1  
					WHERE T1.ComputedReceivableInvoiceId = T2.ComputedReceivableInvoiceId FOR XML PATH('')), 1 ,1, '') AS ReceiptNumberCSV
				FROM #RBFTaxBalanceNotCleared T2
				GROUP BY T2.ComputedReceivableInvoiceId, T2.JobStepInstanceId, T2.Id
			)
			UPDATE RPF
				SET HasError = 1,  RPF.ErrorMessage = REPLACE(@InvoiceTaxBalanceNotClearedForReceiptBatch, '@ReceiptNumbers', RC.ReceiptNumberCSV) 
			OUTPUT deleted.JobStepInstanceId, deleted.GroupNumber INTO #UpdatedReceiptExtract
			FROM ReceiptPostByFileExcel_Extract RPF
			JOIN CTE_ReceiptCSV RC ON RPF.JobStepInstanceId = RC.JobStepInstanceId
			AND RPF.Id = RC.Id
			;
		END

		UPDATE RD
			SET RD.IsValid = 0
		FROM Receipts_Extract RD INNER JOIN #UpdatedReceiptExtract R 
		ON R.GroupNumber = RD.DumpId AND RD.JobStepInstanceId = R.JobStepInstanceId

	END

END

GO
