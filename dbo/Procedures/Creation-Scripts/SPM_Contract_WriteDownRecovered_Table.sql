SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_WriteDownRecovered_Table]
AS
BEGIN

	UPDATE TGT 
	SET RecoveryIncome = SRC.WriteDownRecovered_Table
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (

		SELECT
		EC.ContractId
		,SUM(CASE
				WHEN WD.IsRecovery = 1
				THEN WD.WriteDownAmount_Amount
				ELSE 0.00
			END ) [WriteDownRecovered_Table]
			FROM ##Contract_EligibleContracts EC WITH (NOLOCK)
				INNER JOIN WriteDowns WD WITH(NOLOCK) ON WD.ContractId = EC.ContractId 
			WHERE WD.IsActive = 1
				AND WD.Status = 'Approved' 
						GROUP BY ec.ContractId
			) SRC
		ON (TGT.Id = SRC.ContractId)  
END

GO
