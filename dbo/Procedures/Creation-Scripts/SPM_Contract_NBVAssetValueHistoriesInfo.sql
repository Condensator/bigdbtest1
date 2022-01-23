SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_NBVAssetValueHistoriesInfo]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	     SELECT 
				EC.ContractId,
				SUM(
				CASE
					WHEN (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
						AND (rd.ContractId IS NULL OR (rd.ContractId IS NOT NULL AND lam.CurrentLeaseFinanceId > rd.RenewalFinanceId))
					THEN avh.Value_Amount
					ELSE 0.00
				END) AS NBVImpairment_Table    INTO ##Contract_NBVAssetValueHistoriesInfo		
			FROM ##Contract_EligibleContracts ec
				INNER JOIN LeaseFinances lf ON lf.ContractId = ec.ContractId
				INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
				INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = lam.Id
				INNER JOIN LeaseAssets la ON la.AssetId = avh.AssetId
					AND la.LeaseFinanceId = ec.LeaseFinanceId		
				LEFT JOIN ##Contract_RenewalDetails_OL rd ON rd.ContractId = ec.ContractId
			WHERE avh.IsAccounted = 1
				AND avh.SourceModule = 'NBVImpairments'
				AND avh.GLJournalId IS NOT NULL
				AND avh.ReversalGLJournalId IS NULL
			GROUP BY ec.ContractId;

CREATE NONCLUSTERED INDEX IX_NBVAssetValueHistoriesInfo_ContractId ON ##Contract_NBVAssetValueHistoriesInfo(ContractId);	

END

GO
