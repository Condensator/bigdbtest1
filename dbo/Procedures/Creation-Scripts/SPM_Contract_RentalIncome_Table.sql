SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_RentalIncome_Table]
AS
BEGIN

	UPDATE TGT 
	SET RentalIncome = SRC.RentalIncome_Table
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
	        SELECT EC.ContractId, 
				   ISNULL(lisi.RentalIncome_Table,0.00) AS RentalIncome_Table

		    FROM ##Contract_EligibleContracts EC WITH (NOLOCK)
		    LEFT JOIN ##Contract_LeaseIncomeSchInfo_OL LISI  WITH (NOLOCK) ON LISI.ContractId = EC.ContractId
			) SRC
		
		ON (TGT.Id = SRC.ContractId)  

END

GO
