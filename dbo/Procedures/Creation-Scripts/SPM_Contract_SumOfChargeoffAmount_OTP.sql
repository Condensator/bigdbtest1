SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE   PROC [dbo].[SPM_Contract_SumOfChargeoffAmount_OTP]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT EC.ContractId
	   , SUM(CASE
				   WHEN rard.RecoveryAmount_Amount != 0.00
				   AND Receivables.IncomeType = 'OTP'
				   THEN rard.AmountApplied_Amount
				   ELSE 0
			   END) TotalRecoveryAmount
	   , SUM(CASE
				   WHEN rard.RecoveryAmount_Amount = 0.00
				   AND lps.StartDate >= co.ChargeOffDate
				   AND Receivables.IncomeType = 'OTP'
				   THEN rard.AmountApplied_Amount
				   ELSE 0
			  END) ChargeoffAmount
	   , SUM(CASE
				   WHEN RARD.RecoveryAmount_Amount != 0.00
				   AND Receivables.IncomeType = 'Supplemental'
				   THEN RARD.AmountApplied_Amount
				   ELSE 0
			   END) TotalSupplementalRecoveryAmount
	   , SUM(CASE
				   WHEN RARD.RecoveryAmount_Amount = 0.00
				   AND LPS.StartDate >= CO.ChargeOffDate
				   AND Receivables.IncomeType = 'Supplemental'
				   THEN RARD.AmountApplied_Amount
				   ELSE 0
			  END) SupplementalChargeoffAmount
INTO ##Contract_SumOfChargeoffAmount_OTP
FROM ##Contract_EligibleContracts_OTP EC
	 JOIN ChargeOffs CO  ON CO.ContractId = EC.ContractId 
	      AND CO.isactive=1 AND CO.IsRecovery=0 AND CO.Status='Approved'
     JOIN Receivables  ON EC.ContractId = Receivables.EntityId 
	      AND Receivables.Isactive=1 AND Receivables.FunderId IS NULL AND Receivables.EntityType = 'CT'
		  AND Receivables.FunderId IS NULL
	 JOIN LeasePaymentSchedules LPS  ON LPS.id = Receivables.paymentScheduleId
	 JOIN ReceivableDetails RD  ON RD.ReceivableId = Receivables.Id
	 JOIN ReceiptApplicationReceivableDetails RARD  ON RARD.ReceivableDetailId = RD.Id
	 JOIN ReceiptApplications RA ON RA.Id = RARD.ReceiptApplicationId
	 JOIN Receipts ON Receipts.Id = RA.ReceiptId AND Receipts.Status IN ('Posted','Completed') 
	 WHERE EC.IsOverTermLease = 1
	 GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_SumOfChargeoffAmount_OTPContractId ON ##Contract_SumOfChargeoffAmount_OTP(ContractId) ; 

End

GO
