SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_ValuationExpense]
AS
BEGIN
	UPDATE TGT
	SET TGT.ValuationExpense = SRC.ValuationExpense
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT LeaseFinances.ContractId AS ContractId,
			SUM(CASE WHEN LeaseFinances.HoldingStatus in ('HFS','OriginatedHFS') THEN ValuationAllowances.Allowance_Amount
						   ELSE 0.00 END) AS ValuationExpense
				FROM ValuationAllowances WITH (NOLOCK)
				INNER JOIN LeaseFinances WITH (NOLOCK) ON LeaseFinances.ContractId = ValuationAllowances.ContractId
							AND ValuationAllowances.IsActive = 1 
				INNER JOIN ##ContractMeasures CB ON CB.Id = LeaseFinances.ContractId
				GROUP BY LeaseFinances.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId

END

GO
