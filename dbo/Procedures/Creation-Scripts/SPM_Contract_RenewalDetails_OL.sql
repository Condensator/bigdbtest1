SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_RenewalDetails_OL]
AS
BEGIN
	IF OBJECT_ID('tempdb..#ReceivableInfo') IS NOT NULL
	DROP TABLE #ReceivableInfo;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT	
		EC.ContractId
		,R.Id
		,R.DueDate
		,R.IsGLPosted
		,R.TotalAmount_Amount
		,R.TotalBalance_Amount
		,LPS.StartDate
		, RT.Name AS ReceivableTypeName
	INTO #ReceivableInfo
	FROM ##Contract_EligibleContracts EC
		INNER JOIN Receivables R ON R.EntityId = EC.ContractId
		INNER JOIN ReceivableCodes RC  ON R.ReceivableCodeId = RC.Id
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
		INNER JOIN LeasePaymentSchedules LPS  ON R.PaymentScheduleId = LPS.Id
	WHERE R.IsActive = 1
		AND R.FunderId IS NULL
		AND R.EntityType = 'CT'
		AND RT.Name IN ('OperatingLeaseRental', 'LeaseFloatRateAdj')
		AND R.SourceTable NOT IN ('CPUSchedule','SundryRecurring')
		AND EC.LeaseContractType = 'Operating'
       CREATE NONCLUSTERED INDEX IX_RenewalDetails_OLContractId ON #ReceivableInfo(ContractId);


	   	SELECT LA.ContractId
		,MAX(LAM.CurrentLeaseFinanceId) AS RenewalFinanceId
		,MAX(LAM.AmendmentDate) AS RenewalDate
		,NULL AS ReceivableId
		,NULL AS LeaseIncomeId
	INTO ##Contract_RenewalDetails_OL
	FROM ##Contract_LeaseAmendment_OL LA
		INNER JOIN LeaseFinances LF ON LF.ContractId = LA.ContractId
			AND LA.IsRenewal >= 1
        INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = lf.Id AND LFD.LeaseContractType = 'Operating'
		INNER JOIN LeaseAmendments LAM  ON LF.Id = LAM.CurrentLeaseFinanceId
			AND LAM.AmendmentType = 'Renewal' AND LAM.LeaseAmendmentStatus = 'Approved'
	GROUP BY LA.ContractId;

	
	UPDATE RD
		SET ReceivableId = t.ReceivableId
	FROM ##Contract_RenewalDetails_OL RD
		INNER JOIN (
				SELECT MIN(RI.Id) AS ReceivableId,RI.ContractId
				FROM #ReceivableInfo RI
					INNER JOIN ##Contract_RenewalDetails_OL RD ON RI.ContractId = RD.ContractId
				WHERE RI.StartDate > RD.RenewalDate
					  AND RI.ReceivableTypeName = 'OperatingLeaseRental'
				GROUP BY RI.ContractId) AS t ON t.ContractId = RD.ContractId;
				
	UPDATE RD
		SET LeaseIncomeId = t.LeaseIncomeId
	FROM ##Contract_RenewalDetails_OL RD
		INNER JOIN (
				SELECT MIN(LIS.Id) AS LeaseIncomeId,RD.ContractId
				FROM LeaseIncomeSchedules lis
					INNER JOIN LeaseFinances lf ON LIS.LeaseFinanceId = LF.Id
					INNER JOIN ##Contract_RenewalDetails_OL rd ON LF.ContractId = RD.ContractId
				WHERE LIS.LeaseFinanceId >= RD.RenewalFinanceId
				GROUP BY RD.ContractId) AS t ON t.ContractId = RD.ContractId;
				
	CREATE NONCLUSTERED INDEX IX_RenewalDetailsContractId ON ##Contract_RenewalDetails_OL(ContractId);

	END

GO
