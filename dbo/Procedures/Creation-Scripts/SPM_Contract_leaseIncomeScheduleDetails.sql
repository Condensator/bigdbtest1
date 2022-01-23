SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_leaseIncomeScheduleDetails]
AS

BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT LISD.ContractId, Sum(LISD.earnedsellingprofitincome) - Sum(LISD.earnedspbtwnnacandch) EarnedSellingProfitIncome
	 , SUM(LISD.EarnedIncome) - SUM(LISD.EarnedIncBtwnNACandCh) EarnedIncome
	 , SUM(LISD.EarnedResidualIncome) - SUM(LISD.EarnedResBtwnNACandCh) EarnedResidualIncome
	 , SUM(LISD.Financing_EarnedResidualIncome) - SUM(LISD.FinEarnedResBtwnNACandCh) Financing_EarnedResidualIncome
	 , SUM(LISD.Financing_EarnedIncome) - SUM(LISD.FinEarnedIncBtwnNACandCh) Financing_EarnedIncome

       
INTO  ##contract_leaseIncomeScheduleDetails
FROM   (SELECT EC.ContractId
               ,CASE
                 WHEN LIS.isaccounting = 1
					  AND EC.LeaseContractType != 'Operating'
                      AND LIS.isglposted = 1
                      AND LIS.isnonaccrual = 0
                      AND RL.contractid IS NULL THEN
                 LIS.deferredsellingprofitincome_amount
                 WHEN LIS.isaccounting = 1
				      AND EC.LeaseContractType != 'Operating'
                      AND LIS.isglposted = 1
                      AND LIS.isnonaccrual = 0
                      AND RL.contractid IS NOT NULL
                      AND LIS.leasefinanceid >= RL.renewalfinanceid THEN
                 LIS.deferredsellingprofitincome_amount
                 ELSE 0.00
               END EarnedSellingProfitIncome,
               CASE
                 WHEN LIS.isaccounting = 1
					  AND EC.LeaseContractType != 'Operating'
                      AND LIS.isglposted = 1
                      AND isnonaccrual = 1
                      AND CO.contractid IS NOT NULL
                      AND AC.nonaccrualid IS NOT NULL
                      AND CO.chargeoffdate != AC.nonaccrualdate
                      AND LIS.incomedate >= AC.nonaccrualdate
                      AND LIS.incomedate < CO.chargeoffdate THEN
                 LIS.deferredsellingprofitincome_amount
                 ELSE 0.00
               END AS EarnedSPBtwnNACandCh
			  ,CASE
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NULL 
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					WHEN lis.IsAccounting = 1
						AND lis.IsGLPosted = 1
						AND lis.IsNonAccrual = 0
						AND rl.ContractId IS NOT NULL
					    AND lis.LeaseFinanceID >= rl.RenewalFinanceID
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_EarnedIncome
			    ,CASE 
					WHEN lis.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND lis.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND co.ContractId IS NOT NULL AND ac.NonAccrualId IS NOT NULL
						AND co.ChargeOffDate != ac.NonAccrualDate
						AND lis.IncomeDate >= ac.NonAccrualDate
						AND lis.IncomeDate < co.ChargeOffDate
					THEN lis.FinanceIncome_Amount - lis.FinanceResidualIncome_Amount
					ELSE 0.00
				END AS FinEarnedIncBtwnNACandCh
			  , CASE
					WHEN LIS.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NULL 
					THEN LIS.Income_Amount - LIS.ResidualIncome_Amount
					WHEN LIS.IsAccounting = 1
					    AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NOT NULL
					    AND LIS.LeaseFinanceID >= RL.RenewalFinanceID
					THEN LIS.Income_Amount - LIS.ResidualIncome_Amount
					ELSE 0.00
				 END EarnedIncome
				, CASE 
					WHEN LIS.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND CO.ContractId IS NOT NULL AND AC.NonAccrualId IS NOT NULL
						AND CO.ChargeOffDate != AC.NonAccrualDate
						AND LIS.IncomeDate >= AC.NonAccrualDate
						AND LIS.IncomeDate < CO.ChargeOffDate
					THEN LIS.Income_Amount - LIS.ResidualIncome_Amount
					ELSE 0.00
				END AS EarnedIncBtwnNACandCh
			  , CASE
					WHEN LIS.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NULL
					THEN LIS.ResidualIncome_Amount
					WHEN LIS.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NOT NULL
					    AND LIS.LeaseFinanceID >= RL.RenewalFinanceID
					THEN LIS.ResidualIncome_Amount
					ELSE 0.00
				 END EarnedResidualIncome
				 , CASE
					WHEN LIS.IsAccounting = 1
						AND EC.LeaseContractType != 'Operating'
						AND LIS.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND CO.ContractId IS NOT NULL AND AC.NonAccrualId IS NOT NULL
						AND CO.ChargeOffDate != AC.NonAccrualDate
						AND LIS.IncomeDate >= AC.NonAccrualDate
						AND LIS.IncomeDate < CO.ChargeOffDate
					THEN LIS.ResidualIncome_Amount
					ELSE 0.00
				END AS EarnedResBtwnNACandCh
				, CASE
					WHEN LIS.IsAccounting = 1
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NULL
					THEN LIS.FinanceResidualIncome_Amount
					WHEN LIS.IsAccounting = 1
						AND LIS.IsGLPosted = 1
						AND LIS.IsNonAccrual = 0
						AND RL.ContractId IS NOT NULL
					    AND LIS.LeaseFinanceID >= RL.RenewalFinanceID
					THEN LIS.FinanceResidualIncome_Amount
					ELSE 0.00
				 END Financing_EarnedResidualIncome
				 , CASE 
					WHEN LIS.IsAccounting = 1
						AND LIS.IsGLPosted = 1
						AND IsNonAccrual = 1
						AND CO.ContractId IS NOT NULL AND AC.NonAccrualId IS NOT NULL
						AND CO.ChargeOffDate != AC.NonAccrualDate
						AND LIS.IncomeDate >= AC.NonAccrualDate
						AND LIS.IncomeDate < CO.ChargeOffDate
					THEN LIS.FinanceResidualIncome_Amount
					ELSE 0.00
				END AS FinEarnedResBtwnNACandCh
        FROM   ##Contract_Eligiblecontracts EC
			   INNER JOIN LeaseFinances LF ON LF.ContractId = EC.ContractId 
               INNER JOIN LeaseincomeSchedules lis 
                       ON LIS.leasefinanceid = LF.Id
               LEFT JOIN ##Contract_Chargeoff CO
                      ON CO.contractid = EC.contractid
               LEFT JOIN ##Contract_Accrualdetails AC
                      ON AC.contractid = EC.contractid
               LEFT JOIN ##Contract_Renewaldetails rl
                      ON RL.contractid = EC.contractid
        WHERE  LIS.incometype = 'FixedTerm'
               AND LIS.islessorowned = 1
			   AND LIS.LeaseModificationType != 'Chargeoff') LISD
GROUP  BY Contractid; 

	UPDATE LIS
		SET 
			LIS.EarnedSellingProfitIncome = LIS.EarnedSellingProfitIncome + BI.ReAccrualDeferredSellingProfitIncome_BI
		,	LIS.EarnedIncome = LIS.EarnedIncome + BI.ReAccrualIncome_BI
		,	LIS.EarnedResidualIncome = LIS.EarnedResidualIncome + BI.ReAccrualResidualIncome_BI
		,	LIS.Financing_EarnedResidualIncome = LIS.Financing_EarnedResidualIncome + BI.ReAccrualFinanceResidualIncome_BI
		,	lis.Financing_EarnedIncome = lis.Financing_EarnedIncome + bi.ReAccrualFinanceIncome_BI

	FROM ##Contract_LeaseIncomeScheduleDetails LIS
	INNER JOIN ##Contract_BlendedItemInfo BI on LIS.ContractId = BI.ContractId;

	UPDATE LIS
	SET 
			LIS.EarnedIncome = LIS.EarnedIncome + BIS.ReAccrualEarnedIncome_BIS
		,	LIS.EarnedResidualIncome = LIS.EarnedResidualIncome + BIS.ReAccrualEarnedResidualIncome_BIS_Capital
		,	LIS.EarnedSellingProfitIncome = LIS.EarnedSellingProfitIncome + BIS.ReAccrualEarnedDeferredSellingProfitIncome_BIS
		,	LIS.Financing_EarnedResidualIncome = LIS.Financing_EarnedResidualIncome + BIS.ReAccrualEarnedResidualIncome_BIS
		,	lis.Financing_EarnedIncome = lis.Financing_EarnedIncome + bis.ReAccrualEarnedFinanceIncome_BIS

	FROM ##Contract_LeaseIncomeScheduleDetails LIS
	INNER JOIN ##Contract_BlendedIncomeSchInfo BIS on LIS.ContractId = BIS.ContractId;
			   
CREATE NONCLUSTERED INDEX IX_leaseIncomeScheduleDetailsContractid ON ##Contract_LeaseIncomeScheduleDetails(Contractid)
END

GO
