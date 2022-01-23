SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_NBVImpairment]
AS
BEGIN
	UPDATE TGT
	SET TGT.NBVImpairment = SRC.NBVImpairment
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT
                ec.ContractId,
                ABS(ISNULL(navh.NBVImpairment_Table,0.00)) AS NBVImpairment
            FROM
                ##Contract_EligibleContracts ec WITH (NOLOCK)
                INNER JOIN ##Contract_NBVAssetValueHistoriesInfo navh WITH (NOLOCK) ON navh.ContractId = ec.ContractId
		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
