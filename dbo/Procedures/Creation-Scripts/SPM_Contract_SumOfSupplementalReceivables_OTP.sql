SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_SumOfSupplementalReceivables_OTP]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


SELECT EC.ContractId
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
				   AND RT.name = 'Supplemental'
				   THEN Receivables.TotalAmount_Amount
				   ELSE 0
			   END) TotalSupplementalGLAmount
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
				   AND RT.name = 'Supplemental'
				   THEN Receivables.TotalBalance_Amount
				   ELSE 0
			   END) AS TotalSupplementalGLBalance
		
INTO ##Contract_SumOfSupplementalReceivables_OTP
FROM ##Contract_EligibleContracts_OTP EC
     JOIN Receivables ON EC.ContractId = Receivables.EntityId AND EC.IsOverTermLease = 1
	 JOIN ReceivableCodes RC ON RC.Id = Receivables.ReceivableCodeId
	 JOIN ReceivableTypes RT ON RT.id = RC.receivabletypeid
				AND Receivables.IncomeType = 'Supplemental'
				AND Receivables.FunderId IS NULL
				AND Receivables.EntityType = 'CT'
	 GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_SumOfSupplementalReceivables_OTPContractId ON ##Contract_SumOfSupplementalReceivables_OTP(ContractId) ; 

End

GO
