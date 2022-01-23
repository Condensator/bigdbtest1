SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 
 
CREATE   PROC [dbo].[SPM_Contract_ImpairmentAdjustmentPayoff]
AS
BEGIN
	UPDATE TGT
	SET TGT.ImpairmentAdjustmentPayoff = SRC.ImpairmentAdjustmentPayoff
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			select EC.ContractId as ContractId,
				   SUM(PayoffAssets.AssetValuation_Amount) - SUM(PayoffAssets.NBVAsOfEffectiveDate_Amount) AS ImpairmentAdjustmentPayoff				   				   
			FROM PayoffAssets WITH (NOLOCK)
			INNER JOIN Payoffs WITH (NOLOCK) ON Payoffs.Id = PayoffAssets.PayoffId AND Payoffs.Status = 'Activated' 
			INNER JOIN LeaseFinances WITH (NOLOCK) ON Payoffs.LeaseFinanceId = LeaseFinances.Id 
			INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = LeaseFinances.ContractId 
			GROUP BY EC.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
