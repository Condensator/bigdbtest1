SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_Income_GLPosted]
AS
BEGIN

	UPDATE TGT
	SET TotalGLPostedFloatRateIncome = FRID.Income_GLPosted
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN ##Contract_FloatRateIncomeDetails FRID WITH (NOLOCK) ON FRID.ContractId = TGT.Id

END

GO
