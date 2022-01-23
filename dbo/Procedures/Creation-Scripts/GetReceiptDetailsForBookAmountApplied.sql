SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceiptDetailsForBookAmountApplied]
( 
@JobStepInstanceId BIGINT,
@CustomerEntityType NVARCHAR(10),
@LoanEntityType NVARCHAR(10),
@NonAccrualNonDSLReceiptClassificationType NVARCHAR(30),
@NonAccrualNonDSLNonCashReceiptClassificationType NVARCHAR(30),
@NonCashReceiptClassificationType NVARCHAR(30)
)
AS
BEGIN
SELECT Ar.ACHReceiptId,Ar.ContractId,MAX(DueDate) AS MaxDueDate
INTO #Temp
FROM Receipts_Extract Ar
INNER JOIN ACHReceiptApplicationReceivableDetails RARD ON AR.ID = RARD.ACHRECEIPTiD
INNER JOIN Receivables R ON RARD.RECEIVABLEID = R.iD AND R.IsActive = 1 
WHERE Ar.JobStepInstanceId = @JobStepInstanceId AND RARD.BookAmountApplied IS NULL 
GROUP BY Ar.ACHReceiptId,Ar.ContractId

SELECT R.ACHReceiptId 
INTO #FutureReceivableDetails
FROM Receipts_Extract R 
INNER JOIN LoanFinances LF ON R.ContractId = LF.ContractId
INNER JOIN LoanPaymentSchedules LPR  ON LF.Id = LPR.LoanFinanceId
INNER JOIN #Temp ON R.ACHReceiptId = #Temp.ACHReceiptId AND R.ContractId = #Temp.ContractId
WHERE R.JobStepInstanceId = @JobStepInstanceId AND LF.IsCurrent = 1 AND LPR.DueDate > #Temp.MaxDueDate

SELECT 
       ReceiptId,
       EntityType AS ReceiptEntityType,
	   Currency,
	   ReceivedDate,
	   LegalEntityId,
	   InstrumentTypeId,
	   LineOfBusinessId,
	   CostCenterId,
	   DiscountingId,
	   ReceiptAmount,
	   CustomerId,
	   CASE WHEN SI.StatementInvoiceId IS NOT NULL THEN CAST(1 AS BIT)
	        ELSE CAST(0 AS BIT)
			END AS IsStatementInvoice,
	   CASE WHEN R.EntityType = @LoanEntityType AND (ReceiptClassification = @NonAccrualNonDSLReceiptClassificationType OR ReceiptClassification = @NonAccrualNonDSLNonCashReceiptClassificationType) THEN CAST(1 AS BIT) 
	        ELSE CAST(0 AS BIT)
			END AS IsNonAccrualLoan,
	   CASE WHEN R.EntityType = @LoanEntityType AND (ReceiptClassification = @NonAccrualNonDSLNonCashReceiptClassificationType OR ReceiptClassification = @NonCashReceiptClassificationType) THEN CAST(1 AS BIT) 
	        ELSE CAST(0 AS BIT)
			END AS IsNonCash,
       CASE WHEN FR.ACHReceiptId IS NOT NULL THEN CAST(1 AS BIT)
	        ELSE CAST(0 AS BIT) 
			END AS HasFutureReceivables
FROM Receipts_Extract R
LEFT JOIN #FutureReceivableDetails FR ON R.ACHReceiptId = FR.ACHReceiptId
LEFT JOIN ACHReceiptAssociatedStatementInvoices SI ON R.ACHReceiptId = SI.ACHReceiptId
WHERE R.JobStepInstanceId = @JobStepInstanceId AND R.EntityType IN (@CustomerEntityType,@LoanEntityType) AND R.IsNewReceipt = 1

SELECT 
RE.ReceiptId,
RARD.AmountApplied,
RARD.ReceivableDetailId,
EffectiveBookBalance_Amount as EffectiveBookBalance,
ARD.ReceivableId,
RARD.InvoiceId,
RARD.ContractId,
RE.CustomerId,
RARD.DiscountingId,
RT.Name AS ReceivableType,
ReceivableTypeId,
PaymentScheduleId,
DueDate,
IncomeType,
ARD.InvoiceId AS  ReceivableInvoiceId,
RARD.IsReApplication,
Currency,
RARD.Id AS ReceptApplicationReceivableDetailExtractId,
ARD.Id AS ACHReceptApplicationReceivableDetailId
FROM 
Receipts_Extract RE 
INNER JOIN ACHReceiptApplicationReceivableDetails ARD ON RE.ACHReceiptId = ARD.ACHReceiptId AND ARD.IsActive = 1
INNER JOIN ReceiptApplicationReceivableDetails_Extract RARD ON RARD.ReceiptId = RE.ReceiptId 
                                                            AND RARD.ReceivableDetailId = ARD.ReceivableDetailId
															AND RARD.JobStepInstanceId = RE.JobStepInstanceId
															AND RARD.ReceivableDetailIsActive = 1
INNER JOIN ReceivableDetails RD ON ARD.ReceivableDetailId = RD.Id AND RD.IsActive = 1
INNER JOIN Receivables R ON R.Id = RD.ReceivableId AND R.IsActive = 1
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id AND RC.IsActive = 1
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.IsActive = 1
WHERE RE.EntityType IN (@CustomerEntityType,@LoanEntityType) AND RE.IsNewReceipt = 1 AND ARD.BookAmountApplied =0.00 AND RARD.JobStepInstanceId = @JobStepInstanceId
END;

GO
