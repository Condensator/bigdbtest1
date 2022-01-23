SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_BlendedIncomeSchInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT
		AC.ContractId
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualIncome'
					AND BIS.IsNonAccrual = 0
					AND BIS.PostDate IS NOT NULL
				THEN BIS.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedIncome_BIS]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualFinanceResidualIncome'
					AND BIS.IsNonAccrual = 0
					AND BIS.PostDate IS NOT NULL
				THEN BIS.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedResidualIncome_BIS]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualResidualIncome'
				    AND AC.LeaseContractType != 'Operating'
					AND BIS.IsNonAccrual = 0
					AND BIS.PostDate IS NOT NULL
				THEN BIS.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedResidualIncome_BIS_Capital]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
					AND BIS.IsNonAccrual = 0
					AND BIS.PostDate IS NOT NULL
				THEN BIS.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedDeferredSellingProfitIncome_BIS]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualFinanceIncome'
					AND bis.IsNonAccrual = 0
					AND bis.PostDate IS NOT NULL
				THEN bis.Income_Amount
				ELSE 0.00
			END) [ReAccrualEarnedFinanceIncome_BIS]
			
	INTO ##Contract_BlendedIncomeSchInfo
	FROM ##Contract_AccrualDetails AC
		INNER JOIN LeaseFinances LF ON LF.ContractId = AC.ContractId and AC.ReAccrualId IS NOT NULL
		INNER JOIN BlendedIncomeSchedules BIS ON BIS.LeaseFinanceId = LF.Id
		INNER JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
	WHERE BI.IsActive = 1
		AND BIS.IsAccounting = 1
		AND BIS.ModificationType != 'ChargeOff'
		AND BI.BookRecognitionMode != 'RecognizeImmediately'
		AND 1 = (
					CASE WHEN BI.SystemConfigType IN ('ReAccrualResidualIncome','ReAccrualFinanceIncome') THEN 1
						 WHEN BI.SystemConfigType NOT IN ('ReAccrualResidualIncome','ReAccrualFinanceIncome') AND AC.LeaseContractType != 'Operating' THEN 1
						 ELSE 0
					END	 
		
				)
	GROUP BY AC.ContractId;

	CREATE NONCLUSTERED INDEX IX_BlendedIncomeSchInfoContractId ON ##Contract_BlendedIncomeSchInfo(ContractId);
END

GO
