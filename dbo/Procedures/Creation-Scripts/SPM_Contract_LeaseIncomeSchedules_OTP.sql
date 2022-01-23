SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_LeaseIncomeSchedules_OTP]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT EC.ContractId
	 , SUM(CASE
               WHEN LIS.IsNonAccrual = 0
			   AND LIS.IncomeType = 'OverTerm'
               THEN LIS.RentalIncome_Amount
               ELSE 0
           END) AS RentalIncome
     , SUM(CASE
               WHEN LIS.IsNonAccrual = 1
			   AND LIS.IncomeType = 'OverTerm'
               THEN LIS.RentalIncome_Amount
               ELSE 0
           END) AS SuspendedIncome
	 , SUM(CASE
               WHEN LIS.IsNonAccrual = 1
			   AND LIS.IncomeType = 'Supplemental'
               THEN LIS.RentalIncome_Amount
               ELSE 0
           END) AS SuspendedSupplementalIncome
	, SUM(CASE
               WHEN LIS.IsNonAccrual = 0
			   AND LIS.IncomeType = 'Supplemental'
               THEN LIS.RentalIncome_Amount
               ELSE 0
           END) AS SupplementalRentalIncome
INTO ##Contract_LeaseIncomeSchedules_OTP
FROM ##Contract_EligibleContracts_OTP EC
     INNER JOIN LeaseFinances lf ON lf.ContractId = EC.ContractId
     INNER JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = lf.id
WHERE LIS.IsGLPosted = 1
      AND LIS.IsAccounting = 1 AND EC.IsOverTermLease = 1
GROUP BY EC.ContractId;

CREATE NONCLUSTERED INDEX IX_LeaseIncomeSchedulesContractId ON ##Contract_LeaseIncomeSchedules_OTP(ContractId);
END

GO
