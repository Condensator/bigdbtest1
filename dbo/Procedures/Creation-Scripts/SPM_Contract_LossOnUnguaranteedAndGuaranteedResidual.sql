SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
 
CREATE   PROC [dbo].[SPM_Contract_LossOnUnguaranteedAndGuaranteedResidual]
AS
BEGIN

	UPDATE TGT
	SET FinancingLossOnUnguaranteedResidual = SRC.FinancingLossOnUnguaranteedResidual,
		LossOnUnguaranteedResidual = SRC.LossOnUnguaranteedResidual
    FROM
	##ContractMeasures AS TGT WITH (TABLOCKX)  
	INNER JOIN (
			SELECT SUM(IIF(LA.IsLeaseAsset=0, PVOFAsset_Amount,0)) AS FinancingLossOnUnguaranteedResidual
			,SUM (IIF(LA.IsLeaseAsset=1,PVOFAsset_Amount,0)) AS LossOnUnguaranteedResidual
			,CB.Id AS ContractId
			FROM LeaseAmendmentImpairmentAssetDetails LAIAD WITH (NOLOCK)
			INNER JOIN LeaseAmendments LAD WITH (NOLOCK) ON LAIAD.LeaseAmendmentId = LAD.Id
			INNER JOIN LeaseFinances LF WITH (NOLOCK) ON LAD.CurrentLeaseFinanceId = LF.Id 
			INNER JOIN LeaseAssets LA WITH (NOLOCK) ON  LF.Id = LA.LeaseFinanceId AND LA.AssetId = LAIAD.AssetId
            INNER JOIN ##ContractMeasures CB ON CB.Id = LF.ContractId			
			Where LAIAD.IsActive=1 
			GROUP BY CB.Id
			) SRC

	ON (TGT.Id = SRC.ContractId)  
	

END

GO
