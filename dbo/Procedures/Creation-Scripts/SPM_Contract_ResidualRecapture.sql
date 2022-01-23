SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 

 
CREATE   PROC [dbo].[SPM_Contract_ResidualRecapture]
AS
BEGIN

	UPDATE TGT 
	SET ResidualRecapture = SRC.ResidualRecapture
	FROM
	##ContractMeasures AS TGT WITH (TABLOCKX) 
	INNER JOIN (
	
SELECT ABS(SUM(ResidualRecapture)) AS ResidualRecapture, ContractId 
FROM
(
SELECT Sum(AVHDetails.AmountPosted_Amount) AS ResidualRecapture, CT.ContractId  
	FROM AssetValueHistorydetails AVHdetails WITH(NOLOCK)
	INNER JOIN Assetvaluehistories AVH WITH(NOLOCK) ON AVHdetails.Assetvaluehistoryid = AVH.Id
	INNER JOIN LeaseAssets LA WITH(NOLOCK) ON LA.AssetId = AVH.AssetId 
	INNER JOIN LeaseFinances LF WITH (NOLOCK) ON LA.LeaseFinanceId= LF.Id
	INNER JOIN ##Contract_EligibleContracts CT WITH (NOLOCK) ON CT.LeaseFinanceId = LA.LeaseFinanceId
	INNER JOIN LeaseFinanceDetails LFdetails WITH(NOLOCK) ON LFdetails.Id = LF.Id 
	INNER JOIN ReceivableCodes RC WITH(NOLOCK) ON RC.Id = LFdetails.OTPReceivableCodeId 
WHERE AVH.SourceModule ='ResidualRecapture' AND AVH.IsAccounted=1
	And AVHDetails.IsActive=1 And AVHdetails.ID IS NOT NULL AND RC.AccountingTreatment = 'CashBased' and LF.IsCurrent=1
GROUP BY CT.ContractId                                                               
	UNION                                                                                             
SELECT SUM(AssetValueHistories.Value_Amount) AS ResidualRecapture, CT.ContractId  
	FROM AssetValueHistories WITH(NOLOCK)
	INNER JOIN LeaseAssets WITH(NOLOCK) ON LeaseAssets.AssetId = AssetValueHistories.AssetId
	INNER JOIN LeaseFinances WITH(NOLOCK) ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
	INNER JOIN LeaseFinanceDetails WITH(NOLOCK) ON LeaseFinanceDetails.Id = LeaseFinances.Id
	INNER JOIN ReceivableCodes WITH(NOLOCK) ON ReceivableCodes.Id = LeaseFinanceDetails.OTPReceivableCodeId
	INNER JOIN ##Contract_EligibleContracts CT WITH (NOLOCK) ON CT.ContractId = LeaseFinances.ContractId
WHERE AssetValueHistories.IsAccounted = 1
	AND AssetValueHistories.GLJournalId IS NOT NULL
	AND AssetValueHistories.ReversalGLJournalId IS NULL
	AND AssetValueHistories.SourceModule ='ResidualRecapture'
	AND (LeaseAssets.IsActive = 1
	OR (LeaseAssets.IsActive = 0 AND LeaseAssets.TerminationDate IS NOT NULL))
	AND LeaseFinances.IsCurrent = 1 and ReceivableCodes.AccountingTreatment = 'AccrualBased'
GROUP BY CT.ContractId 
)T
GROUP BY T.ContractId
		
		    ) SRC
ON (TGT.Id = SRC.ContractId)  

END

GO
