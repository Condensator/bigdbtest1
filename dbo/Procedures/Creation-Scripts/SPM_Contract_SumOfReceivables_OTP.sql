SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_SumOfReceivables_OTP]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#SumOfCashBasedReceivables') IS NOT NULL
	DROP TABLE #SumOfCashBasedReceivables;

SELECT EC.ContractId
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
				   AND rt.name = 'OverTermRental'
				   THEN Receivables.TotalAmount_Amount
				   ELSE 0
			   END) TotalGLAmount
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
						AND rt.name = 'OverTermRental'
				   THEN Receivables.TotalBalance_Amount
				   ELSE 0
			   END) AS TotalGLBalance
INTO ##Contract_SumOfReceivables_OTP
FROM ##Contract_EligibleContracts_OTP EC
     JOIN Receivables ON EC.ContractId = Receivables.EntityId
	 JOIN ReceivableCodes rc ON rc.Id = Receivables.ReceivableCodeId
	 JOIN ReceivableTypes rt ON rt.id = rc.receivabletypeid
				AND Receivables.IncomeType = 'OTP'
				AND Receivables.FunderId IS NULL
				AND Receivables.EntityType = 'CT'
				AND Receivables.IsActive = 1
GROUP BY EC.ContractId

CREATE NONCLUSTERED INDEX IX_SumOfNonCashReceivables_OTP_ContractId ON ##Contract_SumOfReceivables_OTP(ContractId);

SELECT ec.ContractId
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
				   AND rt.name = 'OverTermRental'
				   AND rc.AccountingTreatment = 'CashBased'
				   THEN Receivables.TotalAmount_Amount
				   ELSE 0
			   END) TotalCashBased_GLAmount
		, SUM(CASE
				   WHEN Receivables.IsActive = 1
						AND rt.name = 'OverTermRental'
						AND rc.AccountingTreatment = 'CashBased'
				   THEN Receivables.TotalBalance_Amount
				   ELSE 0
			   END) AS TotalCashBased_GLBalance
INTO #SumOfCashBasedReceivables
FROM ##Contract_EligibleContracts_OTP ec
     JOIN Receivables ON ec.ContractId = Receivables.EntityId
	 JOIN ReceivableCodes rc ON rc.Id = Receivables.ReceivableCodeId
	 JOIN ##Contract_ReceivableCode_OTP rca ON rca.OTPReceivableCodeId = rc.Id AND rca.ContractId = ec.ContractId
	 JOIN ReceivableTypes rt ON rt.id = rc.receivabletypeid
				AND Receivables.IncomeType = 'OTP'
				AND Receivables.FunderId IS NULL
				AND Receivables.EntityType = 'CT'
				AND Receivables.IsActive = 1
			GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_SumOfCashBasedReceivables_ContractId ON #SumOfCashBasedReceivables(ContractId);

MERGE ##Contract_SumOfReceivables_OTP AS SumOfReceivables
USING (SELECT * FROM #SumOfCashBasedReceivables) AS SumOfCashBasedReceivables
		ON (SumOfReceivables.ContractId = SumOfCashBasedReceivables.ContractId)
WHEN MATCHED THEN
	UPDATE SET TotalGLAmount = SumOfCashBasedReceivables.TotalCashBased_GLAmount,
			   TotalGLBalance = SumOfCashBasedReceivables.TotalCashBased_GLBalance
WHEN NOT MATCHED THEN
	INSERT (ContractId, TotalGLAmount, TotalGLBalance)
	VALUES (SumOfCashBasedReceivables.ContractId, SumOfCashBasedReceivables.TotalCashBased_GLAmount, SumOfCashBasedReceivables.TotalCashBased_GLBalance);

END

GO
