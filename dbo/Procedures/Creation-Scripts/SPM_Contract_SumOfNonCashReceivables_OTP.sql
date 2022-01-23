SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_SumOfNonCashReceivables_OTP]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT EC.ContractId
		,SUM( rard.AmountApplied_Amount) AS NonCashAmount
INTO ##Contract_SumOfNonCashReceivables_OTP
FROM ##Contract_EligibleContracts_OTP EC 
     JOIN Receivables ON EC.ContractId = Receivables.EntityId
	 JOIN ReceivableDetails rd ON rd.ReceivableId = Receivables.Id
	 JOIN ReceiptApplicationReceivableDetails rard ON rard.ReceivableDetailId = rd.Id
	 JOIN ReceiptApplications ra ON ra.Id = rard.ReceiptApplicationId
	 JOIN Receipts ON Receipts.Id = ra.ReceiptId
	 JOIN ReceivableCodes rc ON rc.Id = Receivables.ReceivableCodeId
	 JOIN ##Contract_ReceivableCode_OTP rca ON rca.OTPReceivableCodeId = rc.Id AND rca.ContractId = EC.ContractId
	WHERE rc.AccountingTreatment = 'CashBased' AND Receipts.Status = 'Completed' AND rard.IsActive = 1
		  AND Receipts.ReceiptClassification != 'Cash'
			GROUP BY EC.ContractId;

CREATE NONCLUSTERED INDEX IX_SumOfNonCashReceivables_OTP_ContractId ON ##Contract_SumOfNonCashReceivables_OTP(ContractId) ; 

END

GO
