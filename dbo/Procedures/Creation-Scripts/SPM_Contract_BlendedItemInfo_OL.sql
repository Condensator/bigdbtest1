SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[SPM_Contract_BlendedItemInfo_OL]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		EC.ContractId
		,SUM(
			CASE
				WHEN BI.SystemConfigType = 'ReAccrualRentalIncome' AND AD.ReAccrualId IS NOT NULL
				THEN BI.Amount_Amount
				ELSE 0.00
			END) [ReAccrualRentalIncome_BI]
	INTO ##Contract_BlendedItemInfo_OL
	FROM ##Contract_EligibleContracts EC
		INNER JOIN LeaseBlendedItems LBI  ON LBI.LeaseFinanceId = EC.LeaseFinanceId AND EC.LeaseContractType = 'Operating'
		INNER JOIN BlendedItems BI ON  LBI.BlendedItemId = BI.Id
		INNER JOIN ##Contract_AccrualDetails_OL AD ON AD.ContractId = EC.ContractId
	WHERE BI.IsActive = 1
		AND BI.BookRecognitionMode = 'RecognizeImmediately'
	GROUP BY EC.ContractId;

	CREATE NONCLUSTERED INDEX IX_BlendedItemInfoContractId_OL ON ##Contract_BlendedItemInfo_OL(ContractId);
	
	END

GO
