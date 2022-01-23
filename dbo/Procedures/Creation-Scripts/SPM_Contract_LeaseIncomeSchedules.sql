SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE   PROC [dbo].[SPM_Contract_LeaseIncomeSchedules]
As
Begin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT EC.ContractId AS ContractId, LIS.IsLessorOwned,LIS.AccountingTreatment,LIS.IsSchedule,LIS.RentalIncome_Amount, 
			LIS.FinanceResidualIncome_Amount
	       ,LIS.IsNonAccrual,LIS.IsAccounting ,LIS.IsGLPosted, EC.InterimRentBillingType, LIS.IncomeType, LIS.LeaseFinanceId
    INTO ##Contract_LeaseIncomeSchedules  
	FROM ##Contract_EligibleContracts EC
	INNER JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = EC.LeaseFinanceId


	CREATE NONCLUSTERED INDEX IX_LeaseIncomeSchedulesContractId ON ##Contract_LeaseIncomeSchedules (ContractId) Include (IncomeType,InterimRentBillingType,AccountingTreatment); 

End

GO
