SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_InterimLeaseIncomeSchInfo]
As
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	DECLARE @DeferInterimRentIncomeRecognition nvarchar(50);
	DECLARE @DeferInterimInterestIncomeRecognition nvarchar(50);
	SELECT @DeferInterimRentIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognition';
	SELECT @DeferInterimInterestIncomeRecognition = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognition';
	DECLARE @DeferInterimInterestIncomeRecognitionForSingleInstallment nvarchar(50);
	SELECT @DeferInterimInterestIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimInterestIncomeRecognitionForSingleInstallment';
	DECLARE @DeferInterimRentIncomeRecognitionForSingleInstallment nvarchar(50);
	SELECT @DeferInterimRentIncomeRecognitionForSingleInstallment = Value FROM GlobalParameters WHERE Category = 'LeaseFinance' AND Name = 'DeferInterimRentIncomeRecognitionForSingleInstallment';

	SELECT
		EC.ContractId
		
		,SUM(
			CASE
				WHEN LIS.IncomeType = 'InterimRent'
					AND LIS.IsAccounting = 1
					AND LIS.IsGLPosted = 1
					AND @DeferInterimRentIncomeRecognition = 'False'
					AND ((EC.InterimRentBillingType = 'Periodic')
						OR (EC.InterimRentBillingType = 'SingleInstallment' 
							AND @DeferInterimRentIncomeRecognitionForSingleInstallment = 'False'))
				THEN LIS.RentalIncome_Amount
				ELSE 0.00
			END) [GLPosted_InterimRentIncome_Table]

		,SUM(
			CASE
				WHEN LIS.IncomeType = 'InterimInterest'
					AND LIS.IsAccounting = 1
					AND LIS.IsGLPosted = 1
					AND @DeferInterimInterestIncomeRecognition = 'False'
					AND ((LFD.InterimInterestBillingType = 'Periodic')
						OR (LFD.InterimInterestBillingType = 'SingleInstallment' 
							AND @DeferInterimInterestIncomeRecognitionForSingleInstallment = 'False'))
				THEN LIS.Income_Amount
				ELSE 0.00
			END) [GLPosted_InterimInterestIncome_Table]
	
	INTO ##Contract_InterimLeaseIncomeSchInfo
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseFinances LF ON LF.ContractId = EC.ContractId 
		INNER JOIN LeaseIncomeSchedules LIS ON LIS.LeaseFinanceId = LF.Id
		INNER JOIN LeaseFinanceDetails LFD ON LFD.Id = EC.LeaseFinanceId
		LEFT JOIN ##Contract_RenewalDetails RN ON RN.ContractId = EC.ContractId
	WHERE LIS.IsLessorOwned = 1
		AND LIS.IncomeType IN ('InterimRent','InterimInterest')
		AND RN.ContractId IS NULL
	GROUP BY EC.ContractId;
	
	CREATE NONCLUSTERED INDEX IX_InterimLeaseIncomeSchInfoContractId ON ##Contract_InterimLeaseIncomeSchInfo(ContractId);
	
	END

GO
