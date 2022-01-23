SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROC [dbo].[SPM_Contract_EarnedResidualIncome]
AS
BEGIN

	UPDATE TGT 
	SET EarnedResidualIncome = SRC.EarnedResidualIncome
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			SELECT EC.ContractId,  
				 (LSD.EarnedResidualIncome ) AS EarnedResidualIncome
			FROM ##Contract_EligibleContracts EC WITH (NOLOCK)
			INNER JOIN ##Contract_LeaseIncomeScheduleDetails LSD WITH (NOLOCK) ON LSD.ContractID = EC.ContractID
		) SRC
		ON (TGT.Id = SRC.ContractId)  
END

GO
