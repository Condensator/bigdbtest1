SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_EligibleContracts_OTP]
As
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	IF OBJECT_ID('tempdb..#RenewalContracts') IS NOT NULL
	DROP TABLE #RenewalContracts;
	IF OBJECT_ID('tempdb..#RenewalOverTermContracts') IS NOT NULL
	DROP TABLE #RenewalOverTermContracts;

SELECT 
	DISTINCT EC.ContractId, MAX(la.CurrentLeaseFinanceId) AS CurrentLeaseFinanceId
	INTO #RenewalContracts
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseFinances LF ON EC.ContractId = LF.ContractId
		INNER JOIN leaseAmendments LA on LA.CurrentLeaseFinanceId = LF.id
	WHERE LA.AmendmentType = 'Renewal' AND EC.IsOverTermLease = 1
	GROUP BY EC.ContractId;
		  		 		 		  
SELECT 
	DISTINCT EC.ContractId
	INTO #RenewalOverTermContracts
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseFinances LF ON EC.ContractId = LF.ContractId
		INNER JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.id
		INNER JOIN #RenewalContracts RC on RC.CurrentLeaseFinanceId = LF.Id
	WHERE LF.Id >= RC.CurrentLeaseFinanceId
		AND LIS.IncomeType = 'OverTerm' AND EC.IsOverTermLease = 1
		AND LIS.IsSchedule=1;

		
SELECT EC.ContractId, EC.LeaseFinanceID , EC.InterimRentBillingType, EC.MaturityDate,  EC.SyndicationType,
	   EC.[AccountingTreatment], EC.LeaseContractType, EC.IsOverTermLease 	   
	INTO ##Contract_EligibleContracts_OTP
	FROM ##Contract_EligibleContracts EC
	WHERE EC.IsOverTermLease = 1 AND EC.ContractId NOT IN
		(
		SELECT RC.ContractId As ContractId
		FROM #RenewalContracts RC WHERE ContractId NOT IN (SELECT ROTC.contractid FROM #RenewalOverTermContracts ROTC)
		);
		
DELETE FROM ##Contract_EligibleContracts_OTP WHERE ContractId NOT IN
(
SELECT ec.ContractId
FROM ##Contract_EligibleContracts_OTP ec
INNER JOIN LeaseFinances lf ON ec.ContractId = lf.ContractId
INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.id
WHERE lis.IncomeType = 'OverTerm');

UPDATE EC
  SET 
      AccountingTreatment = RC.AccountingTreatment
FROM ##Contract_EligibleContracts_OTP EC
INNER JOIN
(
	SELECT EC.ContractId, LFD.Id AS LeaseFinanceDetailId
	FROM LeaseFinanceDetails LFD
		INNER JOIN LeaseFinances LF on LF.Id = LFD.Id
		INNER JOIN ##Contract_EligibleContracts_OTP EC ON EC.ContractId = LF.ContractId
		WHERE LF.IsCurrent = 1
	GROUP BY EC.ContractId, LFD.Id
) As t on t.ContractId = EC.ContractId
	INNER JOIN LeaseFinanceDetails LFD ON t.LeaseFinanceDetailId = LFD.Id
	JOIN RECeivablECodes RC ON RC.Id = LFD.OTPRECeivablECodeId;
	
CREATE NONCLUSTERED INDEX IX_EligibleContracts_OTPContractId ON ##Contract_EligibleContracts_OTP(ContractId);

END

GO
