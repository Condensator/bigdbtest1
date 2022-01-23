SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
 
CREATE   PROC [dbo].[SPM_Contract_EI_SellingProfitEI_FinancingResidualEI]
AS
BEGIN

	UPDATE TGT 
	SET			   EarnedSellingProfitIncome = SRC.EarnedSellingProfitIncome
				  ,EarnedIncome = SRC.EarnedIncome
				  ,FinancingEarnedResidualIncome = SRC.Financing_EarnedResidualIncome
				  ,FinanceEarnedIncome = SRC.Financing_EarnedIncome
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			SELECT EC.ContractId
			     ,  LSD.EarnedSellingProfitIncome
				 ,  LSD.EarnedIncome
				 ,  LSD.Financing_EarnedResidualIncome
				 ,  LSD.Financing_EarnedIncome 
			FROM ##Contract_EligibleContracts EC WITH (NOLOCK)
			INNER JOIN ##Contract_LeaseIncomeScheduleDetails LSD WITH (NOLOCK) ON LSD.ContractID = EC.ContractID

		) SRC
		ON (TGT.Id = SRC.ContractId)   
END

GO
