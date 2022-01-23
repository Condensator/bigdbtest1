SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_BlendedItemInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
		EC.ContractId
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualIncome'
				THEN BI.Amount_Amount
				ELSE 0.00
			END) [ReAccrualIncome_BI]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualDeferredSellingProfitIncome'
				THEN BI.Amount_Amount
				ELSE 0.00
			END) [ReAccrualDeferredSellingProfitIncome_BI]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualFinanceIncome'
				THEN BI.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceIncome_BI]
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualFinanceResidualIncome'
				THEN BI.Amount_Amount
				ELSE 0.00
			END) [ReAccrualFinanceResidualIncome_BI]
		,SUM(
			CASE
				WHEN bi.SystemConfigType = 'ReAccrualResidualIncome'
				THEN bi.Amount_Amount
				ELSE 0.00
			END) [ReAccrualResidualIncome_BI]

	INTO ##Contract_BlendedItemInfo
	FROM ##Contract_EligibleContracts EC 
		INNER JOIN ##Contract_AccrualDetails AC on AC.ContractId = EC.ContractId and AC.ReAccrualId IS NOT NULL
		INNER JOIN LeaseBlendedItems LBI  ON LBI.LeaseFinanceId = EC.LeaseFinanceId
		INNER JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id
	WHERE BI.IsActive = 1
		AND BI.BookRecognitionMode = 'RecognizeImmediately' 
		AND 1 = (
					CASE WHEN BI.SystemConfigType IN ('ReAccrualFinanceResidualIncome','ReAccrualFinanceIncome') THEN 1
					     WHEN BI.SystemConfigType NOT IN ('ReAccrualFinanceResidualIncome','ReAccrualFinanceIncome') AND EC.LeaseContractType != 'Operating' THEN 1
					     ELSE 0 
					END
				)	
	GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_BlendedItemInfoContractId ON ##Contract_BlendedItemInfo(ContractId);
END

GO
