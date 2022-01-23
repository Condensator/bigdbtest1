SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_FloatRateIncomeDetails]
As
Begin
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

	SELECT 
		EC.ContractId
		,SUM(CASE
				WHEN INCOME.IsAccounting = 1
					AND INCOME.IsGLPosted = 1
					AND INCOME.IsNonAccrual = 0
				THEN INCOME.CustomerIncomeAmount_Amount
				ELSE 0.00
			END) [Income_GLPosted]
	INTO ##Contract_FloatRateIncomeDetails
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseFinances LF ON LF.ContractId = EC.ContractId 
		INNER JOIN LeaseFloatRateIncomes INCOME ON INCOME.LeaseFinanceId = LF.Id
		INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = EC.LeaseFinanceId
		LEFT JOIN ##Contract_ChargeOff COD ON COD.ContractId = EC.ContractId
		LEFT JOIN ##Contract_AccrualDetails AD ON AD.ContractId = EC.ContractId
	WHERE (INCOME.IsAccounting = 1
		OR INCOME.IsScheduled = 1)
		AND LFD.IsFloatRateLease = 1
		AND INCOME.IsLessorOwned = 1
		AND INCOME.ModificationType <>'Chargeoff'		
	GROUP BY EC.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_FloatRateIncomeDetailsContractId ON ##Contract_FloatRateIncomeDetails(ContractId);
	End

GO
