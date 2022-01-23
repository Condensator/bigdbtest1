SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_BlendedIncome]
AS
BEGIN
	UPDATE TGT
	SET TGT.BlendedIncome = SRC.BlendedIncome
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
		SELECT SUM(BlendedIncome) AS BlendedIncome, ContractId
		FROM
			(
			 SELECT EC.ContractId as ContractId,  
					SUM(BI.Amount_Amount) AS BlendedIncome
					FROM LeaseBlendedItems LBI WITH (NOLOCK)
					INNER JOIN BlendedItems BI WITH (NOLOCK) on BI.id = LBI.BlendedItemId AND BI.Type = 'Income' 
					AND IsActive = 1 
					INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.LeaseFinanceID = LBI.LeaseFinanceId
					INNER JOIN LeaseFinances LF WITH (NOLOCK) ON LBI.LeaseFinanceId = LF.Id and LF.IsCurrent = 1
					WHERE BI.BookRecognitionMode = 'RecognizeImmediately' 
					AND BI.SystemConfigType NOT IN ('ReAccrualDeferredSellingProfitIncome', 'ReAccruaLFinanceIncome',
													'ReAccruaLFinanceResidualIncome', 'ReAccrualIncome', 'ReAccrualRentalIncome',
													'ReAccrualResidualIncome')
					GROUP BY EC.ContractId
					
					UNION ALL

					SELECT EC.ContractId as ContractId,
					SUM(BIS.Income_Amount) AS BlendedIncome
					FROM BlendedIncomeSchedules BIS WITH (NOLOCK)
					INNER JOIN BlendedItems BI WITH (NOLOCK) ON BI.id = BIS.BlendedItemId AND BI.Type = 'Income' AND IsActive=1 
					LEFT JOIN BlendedItemCodes ON BI.BlendedItemCodeId = BlendedItemCodes.Id
					INNER JOIN  LeaseFinances lf WITH (NOLOCK) ON BIS.LeaseFinanceId = lf. id 
					INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = lf.Contractid 
					WHERE
					((BI.BlendedItemCodeId Is NULL) OR  
					(BI.BlendedItemCodeId Is NOT NULL AND BlendedItemCodes.Name NOT IN ( 'Deferred Servicing Fee', 'Upfront Syndication Fees') ))   
					AND BIS.IsAccounting = 1 AND BIS.PostDate IS NOT NULL AND BIS.IsNonAccrual = 0 AND BI.BookRecognitionMode <> 'RecognizeImmediately'
					AND BIS.ModificationType <>'Chargeoff'
					AND BI.SystemConfigType NOT IN ('ReAccrualDeferredSellingProfitIncome', 'ReAccruaLFinanceIncome',
														'ReAccruaLFinanceResidualIncome', 'ReAccrualIncome', 'ReAccrualRentalIncome',
														'ReAccrualResidualIncome')
			 GROUP BY EC.ContractId) T
	 GROUP BY T.ContractId

		) SRC
		ON TGT.Id = SRC.ContractId
END

GO
