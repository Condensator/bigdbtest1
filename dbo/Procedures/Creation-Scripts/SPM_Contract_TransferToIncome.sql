SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_TransferToIncome]
AS
BEGIN
	UPDATE TGT
	SET TGT.TransferToIncome = SRC.TransferToIncome_Amount
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT EC.ContractId, SUM(SecurityDepositApplications.TransferToIncome_Amount) As TransferToIncome_Amount
			FROM SecurityDepositApplications WITH (NOLOCK)
			INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = SecurityDepositApplications.ContractId
			WHERE SecurityDepositApplications.IsActive=1 and SecurityDepositApplications.GLJournalId IS NOT NULL
			GROUP BY EC.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
