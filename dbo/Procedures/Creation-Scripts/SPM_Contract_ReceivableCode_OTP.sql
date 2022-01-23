SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_ReceivableCode_OTP]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT EC.ContractId
	 , lfd.OTPReceivableCodeId AS OTPReceivableCodeId
INTO ##Contract_ReceivableCode_OTP
FROM ##Contract_EligibleContracts_OTP EC
	 INNER JOIN LeaseFinances lf ON lf.ContractId = EC.ContractId
	 INNER JOIN leaseFinanceDetails lfd ON lfd.Id = lf.Id 
	 WHERE lf.IsCurrent = 1;

CREATE NONCLUSTERED INDEX IX_ReceivableCode_ContractId ON ##Contract_ReceivableCode_OTP(ContractId);

END

GO
