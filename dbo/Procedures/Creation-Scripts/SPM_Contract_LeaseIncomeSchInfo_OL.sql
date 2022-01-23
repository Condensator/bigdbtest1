SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_LeaseIncomeSchInfo_OL]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
		EC.ContractId
		,SUM(
			CASE
				WHEN LIS.IsGLPosted = 1
					AND LIS.IsAccounting = 1
					AND LIS.IsNonAccrual = 0
					AND RD.ContractId IS NULL 
				THEN LIS.RentalIncome_Amount
				WHEN LIS.IsGLPosted = 1
					AND LIS.IsAccounting = 1
					AND LIS.IsNonAccrual = 0
					AND RD.ContractId IS NOT NULL 
					AND LIS.LeaseFinanceId >= RD.RenewalFinanceId 
				THEN LIS.RentalIncome_Amount
				ELSE 0.00
			END) [RentalIncome_Table]
			,SUM(
			CASE
				WHEN LIS.IsSchedule = 1
					AND LIS.IsNonAccrual = 1
					AND cod.ContractId IS NOT NULL AND AD.NonAccrualId IS NOT NULL
					AND cod.ChargeOffDate != AD.NonAccrualDate
					AND LIS.IncomeDate >= AD.NonAccrualDate
					AND LIS.IncomeDate < cod.ChargeOffDate
				THEN LIS.RentalIncome_Amount
				ELSE 0.00
			END) [RentalIncBtwnNACandCh_Table]
	INTO ##Contract_LeaseIncomeSchInfo_OL
	FROM ##Contract_EligibleContracts EC 
	    INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId  
        INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id AND EC.LeaseContractType = 'Operating'    
	    LEFT JOIN ##Contract_ChargeOffDetail COD ON COD.ContractId = EC.ContractId
		LEFT JOIN ##Contract_AccrualDetails_OL AD ON AD.ContractId = EC.ContractId
		LEFT JOIN ##Contract_RenewalDetails_OL RD ON RD.ContractId = EC.ContractId
	WHERE LIS.IncomeType = 'FixedTerm'
		AND LIS.IsLessorOwned = 1
		AND LIS.LeaseModificationType <> 'ChargeOff'
	GROUP BY EC.ContractId;

	
	UPDATE lisi
		SET lisi.RentalIncome_Table = lisi.RentalIncome_Table - lisi.RentalIncBtwnNACandCh_Table
	FROM ##Contract_LeaseIncomeSchInfo_OL lisi;

	UPDATE lisi
		SET lisi.RentalIncome_Table = ISNULL(lisi.RentalIncome_Table,0.00) + ISNULL(bii.ReAccrualRentalIncome_BI,0.00) + ISNULL(bisi.ReAccrualRentalIncome_BIS,0.00)
	FROM ##Contract_EligibleContracts ec
		LEFT JOIN ##Contract_LeaseIncomeSchInfo_OL lisi ON lisi.ContractId = ec.ContractId
		LEFT JOIN ##Contract_BlendedItemInfo_OL bii ON bii.ContractId = ec.ContractId
		LEFT JOIN ##Contract_BlendedIncomeSchInfo_OL bisi ON bisi.ContractId = ec.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_LeaseIncomeSchInfo_OLContractId ON ##Contract_LeaseIncomeSchInfo_OL(ContractId);
	END

GO
