SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

 
CREATE   PROC [dbo].[SPM_Contract_SupplementalIncome]
AS
BEGIN

	UPDATE TGT 
	SET SupplementalIncome = SRC.SupplementalRentalIncome_Schedule
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)	
	INNER JOIN (
			SELECT    CASE
					  WHEN EC.AccountingTreatment = 'CashBased'
					  THEN ISNULL(SOSR.TotalSupplementalGLAmount, 0.00) 
					  - (ISNULL(SOC.TotalSupplementalRecoveryAmount, 0.00) 
					  + ISNULL(SOC.SupplementalChargeoffAmount, 0.00) 
					  + ISNULL(SOSR.TotalSupplementalGLBalance, 0.00)) 
					  ELSE ISNULL(LIS.SupplementalRentalIncome, 0.00)
					  END AS [SupplementalRentalIncome_Schedule]
			         ,EC.ContractId    

    FROM ##Contract_EligibleContracts_OTP EC WITH (NOLOCK)		   
		 LEFT JOIN ##Contract_SumOfSupplementalReceivables_OTP SOSR WITH (NOLOCK) ON SOSR.ContractId = EC.ContractId
		 LEFT JOIN ##Contract_SumOfChargeoffAmount_OTP SOC WITH (NOLOCK) ON SOC.ContractId = EC.ContractId   
		 LEFT JOIN ##Contract_LeaseIncomeSchedules_OTP  LIS WITH (NOLOCK) ON EC.ContractId = LIS.ContractId
		 WHERE EC.IsOverTermLease = 1
		) SRC
		ON (TGT.Id = SRC.ContractId)  
End

GO
