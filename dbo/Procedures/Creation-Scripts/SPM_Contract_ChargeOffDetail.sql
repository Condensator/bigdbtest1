SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_ChargeOffDetail]
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		EC.ContractId
		,CO.ChargeOffDate
	INTO ##Contract_ChargeOffDetail
	FROM ##Contract_EligibleContracts EC
		INNER JOIN ChargeOffs CO ON CO.ContractId = EC.ContractId
	WHERE CO.IsActive = 1
		AND CO.Status = 'Approved'
		AND CO.IsRecovery = 0
		AND CO.ReceiptId IS NULL
		AND EC.LeaseContractType = 'Operating'

	CREATE NONCLUSTERED INDEX IX_ChargeOffDetail_ContractId ON ##Contract_ChargeOffDetail(ContractId);

END

GO
