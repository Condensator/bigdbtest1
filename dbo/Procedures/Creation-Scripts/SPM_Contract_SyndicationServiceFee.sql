SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[SPM_Contract_SyndicationServiceFee]
AS
BEGIN
	UPDATE TGT
	SET TGT.SyndicationServiceFee = SRC.SyndicationServiceFee,
		TGT.SyndicationServiceFeeAbsorb = SRC.SyndicationServiceFeeAbsorb
	FROM ##ContractMeasures AS TGT WITH (TABLOCKX)
		INNER JOIN 
		(
		  SELECT SUM(SyndicationServiceFee) AS SyndicationServiceFee, SUM(SyndicationServiceFeeAbsorb) AS SyndicationServiceFeeAbsorb, ContractId
		  FROM
		   (SELECT EC.ContractId AS ContractId,
			CASE WHEN BlendedItems.Type= 'Income' 
				 THEN SUM(BlendedItems.Amount_Amount) ELSE 0 END AS SyndicationServiceFee,
			CASE WHEN BlendedItems.Type= 'Expense' 	 
				 THEN SUM(BlendedItems.Amount_Amount) ELSE 0 END AS SyndicationServiceFeeAbsorb
			FROM BlendedItems WITH (NOLOCK)
			INNER JOIN BlendedIncomeSchedules WITH (NOLOCK) ON BlendedItems.Id= BlendedIncomeSchedules.BlendeditemId 
			INNER JOIN LeaseFinances  WITH (NOLOCK) ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id 
			INNER JOIN BlendedItemCodes WITH (NOLOCK) ON BlendedItems.BlendedItemCodeId = BlendedItemCodes.Id
			INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = LeaseFinances.Contractid
			WHERE BlendedItems.BookRecognitionMode = 'RecognizeImmediately' AND BlendedItemCodes.Name in ('Deferred Servicing Fee', 'Upfront Syndication Fees') 
			AND BlendedItems.IsActive=1 AND BlendedIncomeSchedules.Postdate IS NOT NULL  AND LeaseFinances.IsCurrent=1 AND BlendedItems.Type IN ('Income','Expense') 
			GROUP BY EC.ContractId, BlendedItems.Type

			UNION ALL

			SELECT EC.ContractId,
			CASE WHEN BlendedItems.Type= 'Income' 
				 THEN SUM(BlendedIncomeSchedules.Income_Amount) ELSE 0 END AS SyndicationServiceFee,
			CASE WHEN BlendedItems.Type= 'Expense'	 
				 THEN SUM(BlendedIncomeSchedules.Income_Amount) ELSE 0 END AS SyndicationServiceFeeAbsorb
			FROM BlendedIncomeSchedules WITH (NOLOCK)
			INNER JOIN BlendedItems WITH (NOLOCK) ON BlendedItems.Id= BlendedIncomeSchedules.BlendeditemId 
			INNER JOIN LeaseFinances WITH (NOLOCK) ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id 
			INNER JOIN BlendedItemCodes WITH (NOLOCK) ON BlendedItems.BlendedItemCodeId = BlendedItemCodes.Id
			INNER JOIN ##Contract_EligibleContracts EC WITH (NOLOCK) ON EC.ContractId = LeaseFinances.Contractid
			WHERE BlendedItems.BookRecognitionMode <> 'RecognizeImmediately' AND BlendedItemCodes.Name in ('Deferred Servicing Fee', 'Upfront Syndication Fees') 
			AND BlendedItems.IsActive=1 AND BlendedIncomeSchedules.Postdate IS NOT NULL  AND BlendedItems.Type IN ('Income','Expense')
			GROUP BY EC.ContractId, BlendedItems.Type
			) T
			GROUP BY T.ContractId

		) SRC
		ON TGT.ID = SRC.ContractId
END

GO
