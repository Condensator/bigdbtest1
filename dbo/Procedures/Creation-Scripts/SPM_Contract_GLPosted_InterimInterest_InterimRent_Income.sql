SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_GLPosted_InterimInterest_InterimRent_Income]
AS
BEGIN

	UPDATE TGT 
	SET GLPostedInterimInterestIncome  = SRC.[GLPosted_InterimInterestIncome_Table]
		,GLPostedInterimRentIncome  = SRC.[GLPosted_InterimRentIncome_Table]
	FROM			  
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
	        SELECT  ContractId 
				   ,[GLPosted_InterimInterestIncome_Table]
				   ,[GLPosted_InterimRentIncome_Table]
			FROM ##Contract_InterimLeaseIncomeSchInfo WITH (NOLOCK)
			) SRC
		
		ON (TGT.Id = SRC.ContractId)  
	
END

GO
