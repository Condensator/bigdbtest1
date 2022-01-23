SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE   PROC [dbo].[SPM_Contract_DepreciationAmount]
AS
BEGIN
	UPDATE TGT
	SET TGT.DepreciationAmount = SRC.DepreciationAmount
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT 
				EC.ContractId,
				ABS(ISNULL(ftavh.DepreciationAmount_Table,0.00)) AS DepreciationAmount
			FROM
				##Contract_EligibleContracts EC WITH (NOLOCK)
				LEFT JOIN  ##Contract_FixedTermAssetValueHistoriesInfo ftavh WITH (NOLOCK) ON ftavh.ContractId = EC.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
