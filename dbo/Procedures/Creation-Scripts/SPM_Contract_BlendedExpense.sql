SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_BlendedExpense]
AS
BEGIN
	UPDATE TGT
	SET TGT.BlendedExpense = SRC.BlendedExpense
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
		SELECT SUM(BlendedExpense) AS BlendedExpense, ContractId 
		FROM	
			(SELECT EC.ContractId AS ContractId,	
			SUM(BI.Amount_Amount) AS BlendedExpense
				FROM LeaseBlendedItems LBI WITH (NOLOCK)
				INNER JOIN BlendedItems BI WITH (NOLOCK) ON BI.id = LBI.BlendedItemId AND BI.Type IN('IDC','Expense') and BI.IsActive=1 
				INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.LeaseFinanceID  = LBI.LeaseFinanceId AND BI.PostDate IS NOT NULL
				INNER JOIN LeaseFinances LF WITH (NOLOCK) ON LBI.LeaseFinanceId = LF.Id and LF.IsCurrent = 1
				WHERE BI.BookRecognitionMode = 'RecognizeImmediately'
				GROUP BY EC.ContractId

			UNION ALL

			SELECT  EC.ContractId AS ContractId,
			 SUM(BIS.Income_Amount) AS BlendedExpense
				FROM BlendedIncomeSchedules BIS WITH (NOLOCK)
				INNER JOIN BlendedItems BI WITH (NOLOCK) ON BI.id = BIS.BlendedItemId And BI.Type IN('IDC','Expense') and BI.IsActive=1 
				INNER JOIN LeaseFinances lf WITH (NOLOCK) ON BIS.LeaseFinanceId = lf. id 
				LEFT JOIN BlendedItemCodes ON BI.BlendedItemCodeId = BlendedItemCodes.Id
				INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId  = lf.Contractid
				WHERE 
				((BI.BlendedItemCodeId Is NULL) OR  
				(BI.BlendedItemCodeId Is NOT NULL AND BlendedItemCodes.Name NOT IN ( 'Deferred Servicing Fee', 'Upfront Syndication Fees') )) 
				AND BI.BookRecognitionMode <> 'RecognizeImmediately' AND BIS.IsAccounting = 1 
				AND BIS.PostDate IS NOT NULL AND BIS.IsNonAccrual = 0 AND BIS.ModificationType <>'Chargeoff'				
				GROUP BY EC.ContractId
				) T
			GROUP BY ContractId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
