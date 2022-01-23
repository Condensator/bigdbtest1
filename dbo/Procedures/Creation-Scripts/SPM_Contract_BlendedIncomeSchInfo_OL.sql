SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

		
	
CREATE   PROC [dbo].[SPM_Contract_BlendedIncomeSchInfo_OL]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		EC.ContractId
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualRentalIncome'
					AND BIS.IsNonAccrual = 0
					AND BIS.PostDate IS NOT NULL
				THEN BIS.Income_Amount
				ELSE 0.00
			END) [ReAccrualRentalIncome_BIS]
	
	INTO ##Contract_BlendedIncomeSchInfo_OL
	FROM ##Contract_EligibleContracts EC
	    INNER JOIN LeaseFinances LF ON LF.ContractId = EC.ContractId
		INNER JOIN BlendedIncomeSchedules BIS ON BIS.LeaseFinanceId = LF.Id  AND EC.LeaseContractType = 'Operating'
		INNER JOIN BlendedItems BI  ON BIS.BlendedItemId = BI.Id
		INNER JOIN ##Contract_AccrualDetails_OL AD ON AD.ContractId = EC.ContractId
			AND AD.ReAccrualId IS NOT NULL
	WHERE BI.IsActive = 1
		AND BIS.IsAccounting = 1
		AND BI.BookRecognitionMode != 'RecognizeImmediately'
	GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_BlendedIncomeSchInfo_OL_ContractId ON ##Contract_BlendedIncomeSchInfo_OL(ContractId);
	
	END

GO
