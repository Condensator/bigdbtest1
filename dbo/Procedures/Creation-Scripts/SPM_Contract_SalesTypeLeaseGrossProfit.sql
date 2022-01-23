SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
 
CREATE   PROC [dbo].[SPM_Contract_SalesTypeLeaseGrossProfit]
AS
BEGIN

	UPDATE TGT 
	SET SalesTypeLeaseGrossProfit = SRC.SalesTypeLeaseGrossProfit_Amount
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			SELECT SUM (SalesTypeLeaseGrossProfit_Amount) as SalesTypeLeaseGrossProfit_Amount, CB.Id AS ContractId
			FROM LeaseFinanceDetails WITH (NOLOCK)
			INNER JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.Id = LeaseFinanceDetails.Id 
			INNER JOIN ##ContractMeasures CB ON CB.Id = LeaseFinances.ContractId
			WHERE LeaseFinances.IsCurrent=1 
			GROUP BY CB.Id
			) SRC

ON (TGT.Id = SRC.ContractId)  

END

GO
