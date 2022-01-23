SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetPayOffPayDownDetailsFromPostByFileExtract]
(
	@JobStepInstanceId		BIGINT,
	@ReceiptPayOffPayDownStatus_PayOff				NVARCHAR(6),
	@ReceiptPayOffPayDownStatus_PayDown				NVARCHAR(7),
	@PaydownStatusValues_Submitted					NVARCHAR(9),
	@PayoffStatusValues_SubmittedForFinalApproval	NVARCHAR(25),
	@PayoffStatusValues_InvoiceGeneration			NVARCHAR(17)
)
AS
BEGIN

	UPDATE RPBF SET
	RPBF.PayOffId=POFF.Id
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN PayoffInvoices POI
	ON RPBF.ComputedReceivableInvoiceId=POI.InvoiceId INNER JOIN Payoffs POFF 
	ON POI.PayoffId = POFF.Id AND (POFF.[Status]=@PayoffStatusValues_SubmittedForFinalApproval OR POFF.[Status]=@PayoffStatusValues_InvoiceGeneration) AND POI.IsActive=1
	WHERE 
		RPBF.HasError=0 AND
		RPBF.JobStepInstanceId=@JobStepInstanceId AND 
		RPBF.IsStatementInvoice=0 AND RPBF.ComputedReceivableInvoiceId IS NOT NULL
		AND (RPBF.NonAccrualCategory IS NULL OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory='GroupedNonRentals')

	UPDATE RPBF SET
	RPBF.PayDownId=LP.Id
	FROM ReceiptPostByFileExcel_Extract RPBF INNER JOIN LoanPaydowns LP ON RPBF.ComputedReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = @PaydownStatusValues_Submitted
	WHERE 
		RPBF.HasError=0 AND
		RPBF.JobStepInstanceId=@JobStepInstanceId AND 
		RPBF.IsStatementInvoice=0 AND RPBF.ComputedReceivableInvoiceId IS NOT NULL
		AND (RPBF.NonAccrualCategory IS NULL OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory='GroupedNonRentals')

	--Non-Accrual Paydown Activation

	SELECT RPBF.Id,RPBF.ReceiptAmount,SUM(ReceivableDetails.EffectiveBalance_Amount) AS PendingBalance
	INTO #NAPayDownAmount
		FROM ReceiptPostByFileExcel_Extract RPBF 
		INNER JOIN ReceivableInvoices ON RPBF.ComputedReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1
		INNER JOIN Receivables ON Receivables.EntityId = RPBF.ComputedContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate <= ReceivableInvoices.DueDate
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE Receivables.IsDummy = 0
			AND RPBF.JobStepInstanceId=@JobStepInstanceId
			AND RPBF.NonAccrualCategory = 'SingleWithRentals'
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal' OR ReceivableInvoices.Id IS NOT NULL)
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
			AND Receivables.DueDate <= ReceivableInvoices.DueDate
		GROUP BY RPBF.Id,RPBF.ReceiptAmount

	UPDATE RPBF SET
	RPBF.PayDownId=LP.Id
	FROM ReceiptPostByFileExcel_Extract RPBF 
	INNER JOIN #NAPayDownAmount ON RPBF.Id = #NAPayDownAmount.Id
	INNER JOIN Contracts ON RPBF.ComputedContractId = Contracts.Id AND Contracts.IsNonAccrual = 1
	INNER JOIN LoanPaydowns LP ON RPBF.ComputedReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = @PaydownStatusValues_Submitted
	WHERE 
		RPBF.CreateUnallocatedReceipt = 0 AND
		RPBF.HasError=0 AND
		RPBF.JobStepInstanceId=@JobStepInstanceId AND 
		RPBF.IsStatementInvoice=0 AND RPBF.ComputedReceivableInvoiceId IS NOT NULL
		AND (RPBF.NonAccrualCategory IS NOT NULL AND RPBF.NonAccrualCategory = 'SingleWithRentals')
		AND #NAPayDownAmount.ReceiptAmount > #NAPayDownAmount.PendingBalance

	--Invalidating group if more than 1 PayOff/PayDown records exist inside a group
	;WITH GroupsToInvalidate AS(
		SELECT GroupNumber
		FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId=@JobStepInstanceId
		AND (PayOffId IS NOT NULL OR PayDownId IS NOT NULL) AND HasError=0
		GROUP BY GroupNumber
		HAVING Count(1) >1
	)
	UPDATE RPBF SET
	RPBF.HasError=1,
	RPBF.ErrorMessage='Group Validation'
	FROM ReceiptPostByFileExcel_Extract RPBF
	INNER JOIN GroupsToInvalidate G ON RPBF.GroupNumber=G.GroupNumber
	WHERE RPBF.JobStepInstanceId=@JobStepInstanceId

	--Returning Data
	;WITH DistinctInvoices AS (
		SELECT DISTINCT ComputedReceivableInvoiceId AS InvoiceId ,NonAccrualCategory FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId=@JobStepInstanceId
		AND (PayOffId IS NOT NULL OR PayDownId IS NOT NULL) AND HasError=0
	)
	,InvoiceBalances AS (
		SELECT I.InvoiceId, SUM(RID.EffectiveBalance_Amount) AS AmountBalance, SUM(RID.EffectiveTaxBalance_Amount) AS TaxBalance
		FROM DistinctInvoices I INNER JOIN ReceivableInvoiceDetails RID 
		ON I.InvoiceId=RID.ReceivableInvoiceId AND RID.IsActive=1
		GROUP BY I.InvoiceId
	)
	SELECT 
	RPBF.Id AS DumpId,
	RPBF.ComputedReceivableInvoiceId AS InvoiceId,
	RPBF.Comment,
	PayOffPayDownStatus=
	CASE
		WHEN RPBF.PayOffId IS NOT NULL THEN @ReceiptPayOffPayDownStatus_PayOff
		WHEN RPBF.PayDownId IS NOT NULL THEN @ReceiptPayOffPayDownStatus_PayDown
	END,
	PayOffPayDownId=
	CASE
		WHEN RPBF.PayOffId IS NOT NULL THEN RPBF.PayOffId
		WHEN RPBF.PayDownId IS NOT NULL THEN RPBF.PayDownId
	END,
	ReceiptAmount = 
	CASE
		WHEN RPBF.NonAccrualCategory = 'SingleWithRentals' THEN RPBF.ReceiptAmount - #NAPayDownAmount.PendingBalance
		ELSE RPBF.ReceiptAmount
	END,
	InvoiceBalance = IB.AmountBalance+IB.TaxBalance
	FROM
	ReceiptPostByFileExcel_Extract RPBF
	INNER JOIN InvoiceBalances IB ON RPBF.ComputedReceivableInvoiceId=IB.InvoiceId
	LEFT JOIN #NAPayDownAmount ON RPBF.Id=#NAPayDownAmount.Id
	WHERE RPBF.JobStepInstanceId=@JobStepInstanceId AND RPBF.HasError=0
	AND (RPBF.PayOffId IS NOT NULL OR RPBF.PayDownId IS NOT NULL)

END

GO
