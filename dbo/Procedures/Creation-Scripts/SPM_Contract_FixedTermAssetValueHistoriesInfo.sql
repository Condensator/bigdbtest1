SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 


CREATE   PROC [dbo].[SPM_Contract_FixedTermAssetValueHistoriesInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	    SELECT
		EC.ContractId
		,SUM(
			CASE
				WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
					AND avh.GLJournalId IS NOT NULL 
					AND avh.ReversalGLJournalId IS NULL
					AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND avh.SourceModuleId >= rd.RenewalFinanceId))
				THEN avh.Value_Amount
				ELSE 0.00
			END) [DepreciationAmount_Table]		
	INTO ##Contract_FixedTermAssetValueHistoriesInfo
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
		INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lf.Id	
		INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
			AND la.LeaseFinanceId = ec.LeaseFinanceId
		LEFT JOIN ##Contract_RenewalDetails rd ON rd.ContractId = ec.ContractId
	WHERE avh.IsAccounted = 1
		AND avh.SourceModule = 'FixedTermDepreciation'
		AND ec.LeaseContractType = 'Operating'
	GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_FixedTermAssetValueHistoriesInfo_ContractId ON ##Contract_FixedTermAssetValueHistoriesInfo(ContractId);			

END

GO
