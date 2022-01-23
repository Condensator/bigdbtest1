SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_NetChargeOff]
AS
BEGIN
	
	UPDATE TGT
	SET TGT.NetChargeOff = SRC.NetChargeOff
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
			SELECT Sum(WriteDowns.WriteDownAmount_Amount) AS NetChargeOff,
			WriteDowns.ContractId AS ContractId
			FROM WriteDowns WITH (NOLOCK)
			INNER JOIN ##ContractMeasures CB ON CB.Id = WriteDowns.ContractId
			Where WriteDowns.PostDate IS NOT NULL AND WriteDowns.IsRecovery=0 And WriteDowns.IsActive=1 
			GROUP BY WriteDowns.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId 
END

GO
