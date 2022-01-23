SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_EarnedSellingProfitIncome]
AS
BEGIN

	UPDATE TGT 
	SET EarnedSellingProfitIncome = SRC.EarnedSellingProfitIncome
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			select EC.ContractId,  ISNULL(LSD.EarnedSellingProfitIncome,0.0) [EarnedSellingProfitIncome]
			FROM ##Contract_EligibleContracts EC WITH (NOLOCK)
			LEFT JOIN ##Contract_LeaseIncomeScheduleDetails LSD WITH (NOLOCK) ON LSD.ContractID = EC.ContractID
		) SRC
		ON (TGT.Id = SRC.ContractId)  
	
END

GO
