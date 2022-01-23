SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 



CREATE   PROC [dbo].[SPM_Contract_OTPDepreciation]
AS
BEGIN

	UPDATE TGT 
	SET OTPDepreciation = SRC.OTPDepreciation
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX) 
	INNER JOIN (
	   SELECT SUM(OTPDepreciation) AS OTPDepreciation, ContractId
	   FROM
		(
		SELECT  ABS( SUM(AVHDetails.AmountPosted_Amount)) AS OTPDepreciation, CB.ID AS ContractId
		FROM    AssetValueHistorydetails AVHdetails WITH(NOLOCK)
				INNER JOIN Assetvaluehistories AVH WITH(NOLOCK) ON AVHdetails.Assetvaluehistoryid = AVH.Id
				INNER JOIN LeaseAssets LA WITH(NOLOCK) ON LA.AssetId = AVH.AssetId 
				INNER JOIN LeaseFinances LF WITH(NOLOCK) ON LA.LeaseFinanceId = LF.Id 
				INNER JOIN LeaseFinanceDetails LFdetails WITH(NOLOCK) ON LFdetails.Id = LF.Id 
				INNER JOIN ReceivableCodes RC WITH(NOLOCK) ON RC.Id = LFdetails.OTPReceivableCodeId 
				INNER JOIN ##ContractMeasures CB WITH(NOLOCK) ON CB.Id = LF.ContractId 
		WHERE AVH.SourceModule IN ('OTPDepreciation','AccumulatedOTPDepreciation') 
				AND AVH.IsAccounted=1 
				AND RC.AccountingTreatment = 'CashBased' and LF.IsCurrent=1		
				AND AVHDetails.IsActive=1 And AVHdetails.ID IS NOT NULL 
				GROUP BY CB.ID		
		UNION																					
		SELECT ABS(SUM(AssetValueHistories.Value_Amount)) AS OTPDepreciation, CB.ID AS ContractId
		FROM AssetValueHistories WITH(NOLOCK)
				INNER JOIN LeaseAssets WITH(NOLOCK) ON LeaseAssets.AssetId = AssetValueHistories.AssetId
				INNER JOIN LeaseFinances WITH(NOLOCK) ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
				INNER JOIN LeaseFinanceDetails WITH(NOLOCK) ON LeaseFinanceDetails.Id = LeaseFinances.Id
				INNER JOIN ReceivableCodes WITH(NOLOCK) ON ReceivableCodes.Id = LeaseFinanceDetails.OTPReceivableCodeId
				INNER JOIN ##ContractMeasures CB WITH(NOLOCK) ON CB.Id = LeaseFinances.ContractId 
		WHERE AssetValueHistories.IsAccounted = 1
				AND AssetValueHistories.SourceModule  IN ('OTPDepreciation','AccumulatedOTPDepreciation')
				AND (LeaseAssets.IsActive = 1 
				OR (LeaseAssets.IsActive = 0 AND LeaseAssets.TerminationDate IS NOT NULL))
				AND LeaseFinances.IsCurrent = 1 and ReceivableCodes.AccountingTreatment = 'AccrualBased'
				AND AssetValueHistories.GLJournalId IS NOT NULL
				AND AssetValueHistories.ReversalGLJournalId IS NULL
				GROUP BY CB.ID
		) T
	 GROUP BY T.ContractId
		    ) SRC
ON (TGT.Id = SRC.ContractId)  

END

GO
