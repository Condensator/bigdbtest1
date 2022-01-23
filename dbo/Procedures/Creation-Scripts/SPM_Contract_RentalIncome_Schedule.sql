SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_RentalIncome_Schedule]
AS
BEGIN
	UPDATE TGT
	SET TGT.OTPIncome = SRC.RentalIncome_Schedule
	FROM ##ContractMeasures TGT
		INNER JOIN 
		(
			SELECT EC.ContractId
				  ,CASE
						   WHEN AccountingTreatment = 'CashBased'
						   THEN ISNULL(sor.TotalGLAmount, 0.00) - 
								(ISNULL(soc.TotalRecoveryAmount, 0.00) + ISNULL(soc.ChargeoffAmount, 0.00) + ISNULL(sor.TotalGLBalance, 0.00)) - ISNULL(soncr.NonCashAmount, 0.00) 
						   ELSE ISNULL(lis.RentalIncome, 0.00)
					   END AS [RentalIncome_Schedule]
			FROM ##Contract_EligibleContracts_OTP EC WITH (NOLOCK)
				 LEFT JOIN ##Contract_LeaseIncomeSchedules_OTP lis WITH (NOLOCK) ON ec.ContractId = lis.ContractId
				 LEFT JOIN ##Contract_SumOfChargeoffAmount_OTP soc WITH (NOLOCK) ON soc.ContractId = ec.ContractId
				 LEFT JOIN ##Contract_SumOfReceivables_OTP sor WITH (NOLOCK) ON sor.ContractId = ec.ContractId
				 LEFT JOIN ##Contract_SumOfNonCashReceivables_OTP soncr WITH (NOLOCK) on soncr.ContractId = ec.contractid

		) SRC
		ON TGT.ID = SRC.ContractId
END

GO
