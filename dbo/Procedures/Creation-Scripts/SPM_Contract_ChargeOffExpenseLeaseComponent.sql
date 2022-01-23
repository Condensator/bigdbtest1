SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_ChargeOffExpenseLeaseComponent]
AS
BEGIN
	UPDATE TGT
	SET TGT.ChargeOffExpenseLeaseComponent = SRC.ChargeOffExpenseLeaseComponent,
		TGT.ChargeOffExpenseNLC = SRC.ChargeOffExpenseNLC
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT EC.ContractId,
				   ISNULL(coi.ChargeOffExpense_LC_Table, 0.00) AS [ChargeOffExpenseLeaseComponent],
				   ISNULL(coi.ChargeOffExpense_NLC_Table, 0.00) AS [ChargeOffExpenseNLC]
			FROM ##Contract_EligibleContracts ec WITH (NOLOCK) 
			LEFT JOIN ##Contract_ChargeOffInfo coi WITH (NOLOCK) ON coi.ContractId = ec.ContractId 
		) SRC
		ON TGT.ID = SRC.ContractId
END

GO
