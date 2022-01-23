SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ReceiptLockBoxNonAccrualValidator]
(
	@JobStepInstanceId			BIGINT,
	@LockboxErrorMessages LockboxErrorMessage READONLY
)
AS
BEGIN
	SET NOCOUNT ON;

	-----------------------------------------------

	DECLARE @ErrorDelimiter AS CHAR = ','

	DECLARE @ErrorMessage_LB413 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB413 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB413'

	DECLARE @ErrorMessage_LB414 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB414 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB414'	
	
	DECLARE @ErrorMessage_LB415 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB415 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB415'	
	
	DECLARE @ErrorMessage_LB419 AS NVARCHAR(200)
	SELECT @ErrorMessage_LB419 = LEM.ErrorMessage FROM @LockboxErrorMessages LEM WHERE LEM.ErrorCode = 'LB419'	

	-----------------------------------------------

	SELECT
		RPBL.LockBoxReceiptId,
		RI.Id AS ReceivableInvoiceId,
		RI.LegalEntityId AS InvoiceLegalEntityId
	INTO #LockBoxInvoiceInfo
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN ReceivableInvoices RI ON RPBL.InvoiceNumber=RI.Number
	WHERE RPBL.InvoiceNumber!='' AND RPBL.InvoiceNumber IS NOT NULL 
	AND RPBL.IsValid=1 AND RPBL.JobStepInstanceId=@JobStepInstanceId

	SELECT
		RPBL.LockBoxReceiptId,
		CTR.Id AS ContractId
	INTO #LockBoxContractInfo
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN Contracts CTR ON RPBL.ContractNumber=CTR.SequenceNumber
	WHERE RPBL.ContractNumber!='' AND RPBL.ContractNumber IS NOT NULL 
	AND RPBL.IsValid=1 AND RPBL.JobStepInstanceId=@JobStepInstanceId
	
	;WITH InvoiceIds AS (
		SELECT RPBL.LockBoxReceiptId, LI.ReceivableInvoiceId, RPBL.ReceivedDate 
		FROM ReceiptPostByLockBox_Extract RPBL INNER JOIN #LockBoxInvoiceInfo LI ON RPBL.LockBoxReceiptId=LI.LockBoxReceiptId
		WHERE RPBL.JobStepInstanceId=@JobStepInstanceId
	), RentalInvoiceInfo AS (
		SELECT distinct I.LockBoxReceiptId, I.ReceivableInvoiceId AS InvoiceId, I.ReceivedDate, CTR.Id AS ContractId
		FROM InvoiceIds I 
		INNER JOIN ReceivableInvoices RI ON I.ReceivableInvoiceId=RI.Id AND RI.IsStatementInvoice = 0
		INNER JOIN ReceivableInvoiceDetails RID ON RI.Id=RID.ReceivableInvoiceId 
		INNER JOIN ReceivableDetails RD	ON RID.ReceivableDetailId=RD.Id AND RD.IsActive=1 
		INNER JOIN Receivables R ON RD.ReceivableId=R.Id AND R.EntityType='CT' AND R.IsActive=1
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id AND RC.IsActive=1
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id AND RT.IsActive=1
		INNER JOIN Contracts CTR ON R.EntityId=CTR.Id AND CTR.ContractType='Loan'
		INNER JOIN LoanFinances LF ON CTR.Id=LF.ContractId AND LF.IsCurrent=1 
		WHERE LF.[Status]!='Cancelled' AND CTR.IsNonAccrual = 1 
		AND (RT.[Name]='LoanInterest' OR RT.[Name]='LoanPrincipal')
		UNION ALL
		SELECT distinct I.LockBoxReceiptId, I.ReceivableInvoiceId AS InvoiceId, I.ReceivedDate, CTR.Id AS ContractId
		FROM InvoiceIds I 
		INNER JOIN ReceivableInvoiceStatementAssociations SA ON I.ReceivableInvoiceId = SA.StatementInvoiceId
		INNER JOIN ReceivableInvoiceDetails RID ON SA.ReceivableInvoiceId=RID.ReceivableInvoiceId 
		INNER JOIN ReceivableDetails RD	ON RID.ReceivableDetailId=RD.Id AND RD.IsActive=1 
		INNER JOIN Receivables R ON RD.ReceivableId=R.Id AND R.EntityType='CT' AND R.IsActive=1
		INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId=RC.Id AND RC.IsActive=1
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId=RT.Id AND RT.IsActive=1
		INNER JOIN Contracts CTR ON R.EntityId=CTR.Id AND CTR.ContractType='Loan'
		INNER JOIN LoanFinances LF ON CTR.Id=LF.ContractId AND LF.IsCurrent=1 
		WHERE LF.[Status]!='Cancelled' AND CTR.IsNonAccrual = 1 
		AND (RT.[Name]='LoanInterest' OR RT.[Name]='LoanPrincipal')
	), ReceiptsForValidating AS (
		SELECT I.LockBoxReceiptId, RANK() OVER (PARTITION BY I.ContractId ORDER BY I.ReceivedDate, LockBoxReceiptId) AS DateRank
		FROM RentalInvoiceInfo I
	), ReceiptsToInValidate AS (
		SELECT distinct LockBoxReceiptId FROM ReceiptsForValidating
		WHERE DateRank!=1
	), ReceiptsToMarkNonAccrual AS (
		SELECT distinct LockBoxReceiptId FROM RentalInvoiceInfo
	)
	UPDATE RPBL SET 
	RPBL.IsNonAccrualLoan = 
	CASE
		WHEN (NA.LockBoxReceiptId IS NOT NULL) THEN 1
		ELSE 0
	END, 
	RPBL.ReceiptClassification = 
	CASE
		WHEN (NA.LockBoxReceiptId IS NOT NULL) THEN 'NonAccrualNonDSL'
		ELSE RPBL.ReceiptClassification
	END,
	RPBL.IsValid=
	CASE
		WHEN (RIV.LockBoxReceiptId IS NOT NULL) THEN 0
		ELSE 1
	END,
	RPBL.ErrorMessage=
	CASE
		WHEN (RIV.LockBoxReceiptId IS NOT NULL) THEN CONCAT(RPBL.ErrorMessage, @ErrorDelimiter, @ErrorMessage_LB413)
		ELSE RPBL.ErrorMessage
	END,
	RPBL.ErrorCode=
	CASE
		WHEN (RIV.LockBoxReceiptId IS NOT NULL) THEN CONCAT(ErrorCode, @ErrorDelimiter, 'LB413')
		ELSE RPBL.ErrorCode
	END
	FROM ReceiptPostByLockBox_Extract RPBL 
	LEFT JOIN ReceiptsToInValidate RIV ON RPBL.LockBoxReceiptId = RIV.LockBoxReceiptId
	LEFT JOIN ReceiptsToMarkNonAccrual NA ON RPBL.LockBoxReceiptId = NA.LockBoxReceiptId
	WHERE RPBL.IsValid=1 AND RPBL.JobStepInstanceId=@JobStepInstanceId

	--Validate Invoice LE with given LE (if provided)
	UPDATE RPBL SET
	RPBL.LegalEntityId=
	CASE
		WHEN (RPBL.LegalEntityNumber IS NULL OR RPBL.LegalEntityNumber='') THEN (LI.InvoiceLegalEntityId)
		ELSE RPBL.LegalEntityId
	END,
	RPBL.IsValid=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LI.InvoiceLegalEntityId) THEN 0
		ELSE 1
	END,
	RPBL.ErrorMessage=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LI.InvoiceLegalEntityId) THEN CONCAT(RPBL.ErrorMessage, @ErrorDelimiter, @ErrorMessage_LB414)
		ELSE RPBL.ErrorMessage
	END,
	RPBL.ErrorCode=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LI.InvoiceLegalEntityId) THEN CONCAT(ErrorCode, @ErrorDelimiter, 'LB414')
		ELSE RPBL.ErrorCode
	END
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN #LockBoxInvoiceInfo LI ON RPBL.LockBoxReceiptId=LI.LockBoxReceiptId
	WHERE RPBL.IsValid=1 AND RPBL.JobStepInstanceId=@JobStepInstanceId AND RPBL.IsNonAccrualLoan=1

	--Contract's LE (if provided contract) should match the given LE (if provided)
	UPDATE RPBL SET
	RPBL.IsValid=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LF.LegalEntityId) THEN 0
		ELSE 1
	END,
	RPBL.ErrorMessage=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LF.LegalEntityId) THEN CONCAT(RPBL.ErrorMessage, @ErrorDelimiter, @ErrorMessage_LB415)
		ELSE RPBL.ErrorMessage
	END,
	RPBL.ErrorCode=
	CASE
		WHEN ((RPBL.LegalEntityNumber IS NOT NULL AND RPBL.LegalEntityNumber!='') AND RPBL.LegalEntityId!=LF.LegalEntityId) THEN CONCAT(ErrorCode, @ErrorDelimiter, 'LB415')
		ELSE RPBL.ErrorCode
	END
	FROM ReceiptPostByLockBox_Extract RPBL
	INNER JOIN #LockBoxContractInfo CTR ON RPBL.LockBoxReceiptId=CTR.LockBoxReceiptId
	LEFT JOIN LoanFinances LF ON CTR.ContractId=LF.ContractId
	WHERE RPBL.IsValid=1 AND RPBL.JobStepInstanceId=@JobStepInstanceId AND RPBL.IsNonAccrualLoan=1

	
	--Non-Accrual Paydown Check
	;WITH ReceivableInfo AS (
		SELECT DISTINCT RPBL.Id,ReceivableInvoiceDetails.EntityId AS ContractID ,
		ReceivableInvoices.Id AS ReceivableInvoiceId,
		ReceivableInvoices.DueDate
		FROM ReceiptPostByLockBox_Extract RPBL
		INNER JOIN ReceivableInvoices ON RPBL.InvoiceNumber = ReceivableInvoices.Number AND ReceivableInvoices.IsActive = 1
		INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
		WHERE ReceivableInvoiceDetails.EntityType = 'CT' AND ReceivableInvoiceDetails.IsActive = 1
			AND RPBL.JobStepInstanceId=@JobStepInstanceId
	)
	SELECT RPBL.Id,RPBL.ReceivedAmount,RINFO.ContractID,RINFO.ReceivableInvoiceId,SUM(ReceivableDetails.EffectiveBalance_Amount) AS PendingBalance
	INTO #NAPayDownAmount
		FROM ReceivableInfo RINFO 
		JOIN ReceiptPostByLockBox_Extract RPBL ON RINFO.Id = RPBL.Id
		INNER JOIN Receivables ON Receivables.EntityId = RINFO.ContractID and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate <= RINFO.DueDate
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE Receivables.IsDummy = 0
			AND RPBL.IsNonAccrualLoan = 1
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal')
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY RPBL.Id,RPBL.ReceivedAmount,RINFO.ContractID,RINFO.ReceivableInvoiceId
				
	UPDATE RPBL SET
	RPBL.Comment=@ErrorMessage_LB419
	FROM ReceiptPostByLockBox_Extract RPBL 
	INNER JOIN #NAPayDownAmount ON RPBL.Id = #NAPayDownAmount.Id
	INNER JOIN Contracts ON #NAPayDownAmount.ContractId = Contracts.Id AND Contracts.IsNonAccrual = 1
	INNER JOIN LoanPaydowns LP ON #NAPayDownAmount.ReceivableInvoiceId=LP.InvoiceId AND LP.[Status] = 'Submitted'
	WHERE 
		RPBL.CreateUnallocatedReceipt = 0 AND
		RPBL.IsValid = 1 AND
		RPBL.JobStepInstanceId=@JobStepInstanceId AND 
		RPBL.IsStatementInvoice=0 AND #NAPayDownAmount.ReceivableInvoiceId IS NOT NULL
		AND RPBL.IsNonAccrualLoan = 1
		AND #NAPayDownAmount.ReceivedAmount <= #NAPayDownAmount.PendingBalance

	DROP TABLE #LockBoxContractInfo
	DROP TABLE #LockBoxInvoiceInfo

END

GO
