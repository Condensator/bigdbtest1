SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetPayOffPayDownDetailsFromLockBoxExtract]
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
	
	UPDATE RPBL SET
	RPBL.PayOffId=POFF.Id
	FROM ReceiptPostByLockBox_Extract RPBL INNER JOIN PayoffInvoices POI
	ON RPBL.ReceivableInvoiceId=POI.InvoiceId INNER JOIN Payoffs POFF 
	ON POI.PayoffId = POFF.Id AND (POFF.[Status]=@PayoffStatusValues_SubmittedForFinalApproval OR POFF.[Status]=@PayoffStatusValues_InvoiceGeneration) AND POI.IsActive=1
	WHERE 
		RPBL.IsValid=1 AND
		RPBL.JobStepInstanceId=@JobStepInstanceId AND 
		RPBL.IsStatementInvoice=0 AND RPBL.ReceivableInvoiceId IS NOT NULL
		AND RPBL.IsNonAccrualLoan=0

	UPDATE RPBL SET
	RPBL.PayDownId=LP.Id
	FROM ReceiptPostByLockBox_Extract RPBL INNER JOIN LoanPaydowns LP ON RPBL.ReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = @PaydownStatusValues_Submitted
	WHERE 
		RPBL.IsValid=1 AND
		RPBL.JobStepInstanceId=@JobStepInstanceId AND 
		RPBL.IsStatementInvoice=0 AND RPBL.ReceivableInvoiceId IS NOT NULL
		AND RPBL.IsNonAccrualLoan=0

	--Non-Accrual Paydown Activation
	;WITH ContractInfo AS
	(
	SELECT DISTINCT RPBL.ReceivableInvoiceId,ReceivableInvoiceDetails.EntityId AS ContractId FROM ReceiptPostByLockBox_Extract RPBL  
		INNER JOIN ReceivableInvoiceDetails ON RPBL.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
		WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
	)
	SELECT RPBL.Id,RPBL.ReceivedAmount,SUM(ReceivableDetails.EffectiveBalance_Amount) AS PendingBalance,ContractInfo.ContractId
	INTO #NAPayDownAmount
		FROM ReceiptPostByLockBox_Extract RPBL 
		INNER JOIN ReceivableInvoices ON RPBL.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1
		INNER JOIN ContractInfo ON ContractInfo.ReceivableInvoiceId = RPBL.ReceivableInvoiceId
		INNER JOIN Receivables ON Receivables.EntityId = ContractInfo.ContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate <= ReceivableInvoices.DueDate
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE Receivables.IsDummy = 0
			AND RPBL.JobStepInstanceId=@JobStepInstanceId
			AND RPBL.IsNonAccrualLoan = 1
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal' OR ReceivableInvoices.Id IS NOT NULL)
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
			AND Receivables.DueDate <= ReceivableInvoices.DueDate
		GROUP BY RPBL.Id,RPBL.ReceivedAmount,ContractInfo.ContractId

	UPDATE RPBL SET
	RPBL.PayDownId=LP.Id
	FROM ReceiptPostByLockBox_Extract RPBL 
	INNER JOIN #NAPayDownAmount ON RPBL.Id = #NAPayDownAmount.Id
	INNER JOIN Contracts ON #NAPayDownAmount.ContractId = Contracts.Id AND Contracts.IsNonAccrual = 1
	INNER JOIN LoanPaydowns LP ON RPBL.ReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = @PaydownStatusValues_Submitted
	WHERE 
		RPBL.CreateUnallocatedReceipt = 0 AND
		RPBL.IsValid = 1 AND
		RPBL.JobStepInstanceId=@JobStepInstanceId AND 
		RPBL.IsStatementInvoice=0 AND RPBL.ReceivableInvoiceId IS NOT NULL
		AND RPBL.IsNonAccrualLoan = 1
		AND #NAPayDownAmount.ReceivedAmount > #NAPayDownAmount.PendingBalance

	--Returning Data
	;WITH DistinctInvoices AS (
		SELECT DISTINCT ReceivableInvoiceId AS InvoiceId FROM ReceiptPostByLockBox_Extract WHERE JobStepInstanceId=@JobStepInstanceId
		AND (PayOffId IS NOT NULL OR PayDownId IS NOT NULL) AND IsValid=1
	)
	,InvoiceBalances AS (
		SELECT I.InvoiceId, SUM(RID.EffectiveBalance_Amount) AS AmountBalance, SUM(RID.EffectiveTaxBalance_Amount) AS TaxBalance
		FROM DistinctInvoices I INNER JOIN ReceivableInvoiceDetails RID 
		ON I.InvoiceId=RID.ReceivableInvoiceId AND RID.IsActive=1
		GROUP BY I.InvoiceId
	)
	SELECT 
	RPBL.Id AS DumpId,
	RPBL.ReceivableInvoiceId AS InvoiceId,
	RPBL.Comment,
	PayOffPayDownStatus=
	CASE
		WHEN RPBL.PayOffId IS NOT NULL THEN @ReceiptPayOffPayDownStatus_PayOff
		WHEN RPBL.PayDownId IS NOT NULL THEN @ReceiptPayOffPayDownStatus_PayDown
	END,
	PayOffPayDownId=
	CASE
		WHEN RPBL.PayOffId IS NOT NULL THEN RPBL.PayOffId
		WHEN RPBL.PayDownId IS NOT NULL THEN RPBL.PayDownId
	END,
	ReceiptAmount = 
	CASE
		WHEN RPBL.IsNonAccrualLoan = 1 THEN RPBL.ReceivedAmount - #NAPayDownAmount.PendingBalance
		ELSE RPBL.ReceivedAmount
	END,
	InvoiceBalance = IB.AmountBalance+IB.TaxBalance
	FROM
	ReceiptPostByLockBox_Extract RPBL
	INNER JOIN InvoiceBalances IB ON RPBL.ReceivableInvoiceId=IB.InvoiceId
	LEFT JOIN #NAPayDownAmount ON RPBL.Id=#NAPayDownAmount.Id
	WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
	AND (RPBL.PayOffId IS NOT NULL OR RPBL.PayDownId IS NOT NULL)

END

GO
