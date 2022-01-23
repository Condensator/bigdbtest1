SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceiptSummariesForCustomerService]
(
	@CustomerNumber				NVARCHAR(50),
	@UserID						BIGINT,
	@AccessibleLegalEntityIds	NVARCHAR(MAX)
)
AS

--DECLARE
--	@CustomerNumber				NVARCHAR(50) = '7180',
--	@UserID						BIGINT = 1,
--	@AccessibleLegalEntityIds	NVARCHAR(MAX) = '1'

BEGIN
	SET NOCOUNT ON

	SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntityIds, ',')

	DECLARE @CustomerId BIGINT = (SELECT Id FROM Parties WHERE PartyNumber = @CustomerNumber)

	CREATE TABLE #EntityIds (EntityId BIGINT,EntityType NVARCHAR(4))

	--SELECT
	--	DISTINCT C.[Id] INTO #ValidContractIds
	--FROM(
			SELECT C.ID INTO #InValidContractIds
			FROM  [dbo].[Contracts] AS C
				INNER JOIN [dbo].[EmployeesAssignedToContracts] AS EAC ON C.[Id] = EAC.[ContractId]
				INNER JOIN [dbo].[EmployeesAssignedToParties] AS EAP ON EAC.[EmployeeAssignedToPartyId] = EAP.[Id]
			WHERE EAP.[EmployeeId] <> @UserId AND C.[IsConfidential] = 1
		--UNION ALL
		--	SELECT Id
		--	FROM Contracts WHERE IsConfidential = 0
		--) C

	CREATE NONCLUSTERED INDEX IX_#ValidContractIds_Id ON [dbo].[#InValidContractIds] ( [Id] ) ;

	INSERT INTO #EntityIds
	SELECT ContractId, 'CT'
	FROM LeaseFinances
	WHERE IsCurrent = 1
		AND LeaseFinances.CustomerId = @CustomerId
		AND ContractId NOT IN (SELECT ID FROM #InValidContractIds)

	INSERT INTO #EntityIds
	SELECT ContractId, 'CT'
	FROM LoanFinances
	WHERE IsCurrent = 1
		AND LoanFinances.CustomerId = @CustomerId
		AND ContractId NOT IN (SELECT ID FROM #InValidContractIds)

	INSERT INTO #EntityIds
	SELECT DISTINCT CAH.ContractId, 'CT'
	FROM ContractAssumptionHistories CAH
	INNER JOIN Assumptions A ON A.Id = CAH.AssumptionId
		AND CAH.CustomerId = @CustomerId;

	INSERT INTO #EntityIds SELECT @CustomerId, 'CU'

	CREATE TABLE #Receipts
	(
		ReceiptId					BIGINT,
		Number						NVARCHAR(40)
	)

	CREATE NONCLUSTERED INDEX IX#Receipts_ReceiptId ON [#Receipts] ([ReceiptId])

	SELECT ReceivableDetails.Id INTO #ReceivableDetails FROM ReceivableDetails
			INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
			AND Receivables.CustomerId = @CustomerId
			AND Receivables.IsActive = 1
			AND ReceivableDetails.IsActive = 1

	SELECT 
		RARD.Id INTO #ReceiptApplicationReceivableDetails FROM ReceiptApplications RA
		INNER JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId
		INNER JOIN #ReceivableDetails ON RARD.ReceivableDetailId = #ReceivableDetails.Id
		AND RARD.IsActive = 1
		GROUP BY RARD.Id

	SELECT
		Receipts.Id,
		Receipts.Number,
		CASE
			WHEN (Receipts.ReceiptClassification = 'Cash' OR Receipts.ReceiptClassification = 'NonCash')
				THEN SUM(rard.ReceivedAmount_Amount)
				ELSE SUM(rard.AmountApplied_Amount + rard.TaxApplied_Amount) END
			AS AmountAppliedToCharges,
		SUM(RARD.TaxApplied_Amount) AS AmountAppliedToTaxes
	INTO #CTE_ReceiptReceivableDetails
	FROM Receipts
		INNER JOIN ReceiptApplications AS RA ON Receipts.Id = RA.ReceiptId
		INNER JOIN ReceiptApplicationReceivableDetails AS RARD ON RA.Id = RARD.ReceiptApplicationId
		INNER JOIN #ReceiptApplicationReceivableDetails ON RARD.Id = #ReceiptApplicationReceivableDetails.Id
	GROUP BY
	Receipts.Id,
	Receipts.Number,
	RARD.ReceivableDetailId,
	Receipts.ReceiptClassification
	DROP TABLE #ReceiptApplicationReceivableDetails
	INSERT INTO #Receipts(ReceiptId, Number)
	(
		SELECT
			Id,
			Number
		FROM #CTE_ReceiptReceivableDetails
		WHERE (AmountAppliedToCharges + AmountAppliedToTaxes) != 0
		GROUP BY Id, Number
	)

			INSERT INTO #Receipts(ReceiptId, Number)
			SELECT
				Receipts.Id,
				Receipts.Number
			FROM Receipts
				INNER JOIN #AccessibleLegalEntityIds ON Receipts.LegalEntityId  = #AccessibleLegalEntityIds.Id
				LEFT JOIN #Receipts  on #Receipts.ReceiptId = Receipts.Id 
			WHERE CustomerId = @CustomerId AND #Receipts.ReceiptId IS NULL

			INSERT INTO #Receipts(ReceiptId, Number)
			SELECT
				Receipts.Id,
				Receipts.Number
			FROM Receipts
				INNER JOIN #AccessibleLegalEntityIds ON Receipts.LegalEntityId  = #AccessibleLegalEntityIds.Id
				INNER JOIN #EntityIds ON #EntityIds.EntityId =  Receipts.ContractId AND #EntityIds.EntityType ='CT'
				LEFT JOIN #Receipts  on #Receipts.ReceiptId = Receipts.Id 
			WHERE #Receipts.ReceiptId IS NULL



	SELECT
		R.Number AS ReceiptNumber,
		CC.ISO AS Currency,
		R.ReceivedDate AS ReceivedDate,
		R.Status AS Status,
		R.PostDate AS PostDate,
		RT.ReceiptTypeName AS ReceiptTypeName,
		RB.Name AS BatchName,
		R.CheckNumber AS CheckNumber,
		CASE
			WHEN R.ReceiptClassification <> 'NonCash' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'
				THEN R.ReceiptAmount_Amount
				ELSE CAST(0 AS Decimal(16,2))
			END CheckAmount,
		R.Balance_Amount AS UnallocatedCashAmount,
		R.Id AS ReceiptID,
		R.NonCashReason,
		RRR.Code [ReversalReason],
		CASE WHEN R.ReceiptClassification = 'NonCash' OR R.ReceiptClassification =  'NonAccrualNonDSLNonCash' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsNonCash,
		CAST(0 AS Decimal(16,2)) AmountAppliedToCharges,
		CAST(0 AS Decimal(16,2)) AmountAppliedToTaxes,
		CAST(0 AS Decimal(16,2)) CreditAmountApplied,
		CAST(0 AS Decimal(16,2)) AdjustedWithHoldingTax,
		R.ReceiptAmount_Amount Receipt_Amount,
		R.Balance_Amount,
		R.ReceiptClassification
		INTO #ReceiptSummaries
	FROM Receipts R
		INNER JOIN #Receipts Receipt ON Receipt.ReceiptId = R.Id
		INNER JOIN Currencies C ON R.CurrencyId = C.Id
		INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
		INNER JOIN ReceiptTypes RT ON R.TypeId = RT.Id
		LEFT JOIN ReceiptBatches RB ON R.ReceiptBatchId = RB.Id
		LEFT JOIN ReceiptReversalReasons RRR ON R.ReversalReasonId = RRR.Id

	CREATE TABLE #CreditAppliedAmountsForReceipt(SumCreditApplied DECIMAL(16,2),ReceiptId BIGINT)

	INSERT INTO #CreditAppliedAmountsForReceipt(SumCreditApplied,ReceiptId)
	SELECT
		SUM(RA.CreditApplied_Amount) AS SumCreditApplied
		,R.ReceiptId
	FROM #Receipts AS R
		INNER JOIN ReceiptApplications AS RA ON R.ReceiptId = RA.ReceiptId
	GROUP BY R.ReceiptId;

	SELECT
		#ReceiptSummaries.ReceiptID,SUM(UnallocatedRefundDetails.AmountToBeCleared_Amount) RefundAmount
	INTO #ReceiptRefunds
	FROM UnallocatedRefundDetails
		JOIN UnallocatedRefunds ON UnallocatedRefundDetails.UnallocatedRefundId = UnallocatedRefunds.Id AND UnallocatedRefunds.Status='Approved'
		JOIN ReceiptAllocations ON UnallocatedRefundDetails.ReceiptAllocationId = ReceiptAllocations.Id
		JOIN #ReceiptSummaries ON ReceiptAllocations.ReceiptId = #ReceiptSummaries.ReceiptID
	GROUP BY #ReceiptSummaries.ReceiptID;

	CREATE TABLE #AllocatedReceiptDetails
	(
		AmountAppliedToCharges	DECIMAL(16,2),
		AmountAppliedToTaxes	DECIMAL(16,2),
		CreditAmountApplied		DECIMAL	(16,2),
		TotalAmountApplied		DECIMAL(16,2),
		AdjustedWithHoldingTax	DECIMAL(16,2),
		ReceiptID				BIGINT
	)

	INSERT INTO #AllocatedReceiptDetails
		(AmountAppliedToCharges,AmountAppliedToTaxes,TotalAmountApplied,CreditAmountApplied,AdjustedWithHoldingTax,ReceiptID)
	SELECT
		 SUM(AmountAppliedToCharges) AmountAppliedToCharges
		,SUM(AmountAppliedToTaxes) AmountAppliedToTaxes
		,SUM(TotalAmountApplied) TotalAmountApplied
		,SUM(CreditApplied) AS CreditApplied
		,SUM(AdjustedWithHoldingTax) AS AdjustedWithHoldingTax
		,RID AS ReceiptID
	FROM
		(
			SELECT
				CASE
					WHEN (R.ReceiptClassification = 'Cash' OR R.ReceiptClassification = 'NonCash')
						THEN SUM(rard.ReceivedAmount_Amount)
						ELSE SUM(rard.AmountApplied_Amount + rard.TaxApplied_Amount) END
					AS AmountAppliedToCharges,
				SUM(rard.TaxApplied_Amount) AS AmountAppliedToTaxes,
				SUM(rard.AmountApplied_Amount + rard.TaxApplied_Amount) AS TotalAmountApplied,
				SUM(RAp.CreditApplied_Amount) AS CreditApplied,
				SUM(RARD.AdjustedWithHoldingTax_Amount) AS AdjustedWithHoldingTax,
				R.ReceiptID 'RID'
			FROM #ReceiptSummaries  R
				INNER JOIN ReceiptApplications RAp ON R.ReceiptID = RAp.ReceiptId
				INNER JOIN ReceiptApplicationReceivableDetails rard ON RAp.Id = rard.ReceiptApplicationId
					AND rard.IsActive = 1
				INNER JOIN #ReceivableDetails ON rard.ReceivableDetailId = #ReceivableDetails.Id
				LEFT JOIN #ReceiptRefunds ON R.ReceiptID = #ReceiptRefunds.ReceiptID
			GROUP BY R.ReceiptID,RARD.ReceivableDetailId,R.ReceiptClassification
			HAVING (SUM(rard.AmountApplied_Amount)+SUM(rard.TaxApplied_Amount)) > 0
					OR ((SUM(rard.AmountApplied_Amount)+SUM(rard.TaxApplied_Amount)) = 0
				AND MIN(R.Receipt_Amount) = MIN(R.Balance_Amount)+MIN(ISNULL(#ReceiptRefunds.RefundAmount,0)))
		)T
	GROUP BY RID;

	CREATE TABLE #UnAllocatedReceiptDetails
	(
		AmountAppliedToCharges	DECIMAL(16,2),
		AmountAppliedToTaxes	DECIMAL(16,2),
		CreditAmountApplied		DECIMAL(16,2),
		TotalAmountApplied		DECIMAL(16,2),
		AdjustedWithHoldingTax	DECIMAL(16,2),
		ReceiptID				BIGINT
	)

	INSERT INTO #UnAllocatedReceiptDetails (AmountAppliedToCharges,AmountAppliedToTaxes,TotalAmountApplied,CreditAmountApplied,AdjustedWithHoldingTax,ReceiptID)
	SELECT
		SUM(ISNULL(rard.AmountApplied_Amount,0)+ ISNULL(rard.TaxApplied_Amount,0)) AS AmountAppliedToCharges,
		0.00 AS AmountAppliedToTaxes,
		SUM(ISNULL(rard.AmountApplied_Amount,0)+ ISNULL(rard.TaxApplied_Amount,0)) AS TotalAmountApplied,
		SUM(RAp.CreditApplied_Amount) AS CreditApplied,
		0.00,
		R.ReceiptID
	FROM #ReceiptSummaries  R
		INNER JOIN Receipts ON R.ReceiptId = Receipts.Id
		INNER JOIN ReceiptApplications RAp ON R.ReceiptID = RAp.ReceiptId
		LEFT JOIN ReceiptApplicationReceivableDetails rard ON RAp.Id = rard.ReceiptApplicationId
	WHERE Receipts.Id NOT IN (SELECT ReceiptId FROM #AllocatedReceiptDetails)
		AND (rard.Id IS NULL)
	GROUP BY R.ReceiptID

	CREATE TABLE #UpdateAmountForReceipts
	(
		AmountAppliedToCharges	DECIMAL(16,2),
		AmountAppliedToTaxes	DECIMAL(16,2),
		CreditAmountApplied		DECIMAL(16,2),
		TotalAmountApplied		DECIMAL(16,2),
		AdjustedWithHoldingTax	DECIMAL(16,2),
		ReceiptID				BIGINT
	)

	INSERT INTO #UpdateAmountForReceipts (AmountAppliedToCharges,AmountAppliedToTaxes,TotalAmountApplied,CreditAmountApplied, AdjustedWithHoldingTax, ReceiptID)
			SELECT
				AmountAppliedToCharges,
				AmountAppliedToTaxes,
				TotalAmountApplied,
				CreditAmountApplied,
				AdjustedWithHoldingTax,
				ReceiptID
			FROM #UnAllocatedReceiptDetails
		UNION
			SELECT
				AmountAppliedToCharges,AmountAppliedToTaxes,TotalAmountApplied,CreditAmountApplied, AdjustedWithHoldingTax, ReceiptID
			FROM #AllocatedReceiptDetails
		UNION
			SELECT
				SUM(RAp.AmountApplied_Amount) AS AmountAppliedToCharges,
				0.00 AS AmountAppliedToTaxes,
				SUM(RAp.AmountApplied_Amount) AS TotalAmountApplied,
				SUM(RAp.CreditApplied_Amount) AS CreditApplied,
				0.00 AS AdjustedWithHoldingTax,
				R.ReceiptID
			FROM #ReceiptSummaries  R
				INNER JOIN ReceiptApplications RAp ON R.ReceiptID = RAp.ReceiptId
					AND R.ReceiptTypeName = 'EscrowRefund'
			GROUP BY R.ReceiptID

	SELECT
		R.ReceiptNumber AS ReceiptNumber,
		R.Currency AS Currency,
		R.ReceivedDate AS ReceivedDate,
		R.Status AS Status,
		R.PostDate AS PostDate,
		R.ReceiptTypeName AS ReceiptTypeName,
		R.BatchName AS BatchName,
		R.CheckNumber AS CheckNumber,
		CASE
			WHEN R.IsNonCash = 0 AND R.ReceiptTypeName <> 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.TotalAmountApplied,0) + R.UnallocatedCashAmount - ISNULL(CreditAppliedAmountsForReceipt.SumCreditApplied,0)
				ELSE R.CheckAmount
			END  AS  CheckAmount,
		R.UnallocatedCashAmount AS UnallocatedCashAmount,
		CASE
			WHEN R.IsNonCash = 0 AND R.ReceiptTypeName <> 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.AmountAppliedToCharges,0)
				ELSE 0
			END	AS AmountAppliedToCharges,
		CASE
			WHEN R.IsNonCash = 0 AND R.ReceiptTypeName <> 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.AmountAppliedToTaxes,0)
				ELSE 0
			END  AS	AmountAppliedToTaxes,
		CASE
			WHEN R.IsNonCash = 0 AND R.ReceiptTypeName <> 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.TotalAmountApplied,0)
				ELSE 0
			END  AS	TotalAmountApplied,
		R.ReceiptID Id,
		CASE
			WHEN R.ReceiptTypeName <> 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.AdjustedWithHoldingTax,0)
				ELSE 0
			END	AS AdjustedWithHoldingTax,
		CASE
			WHEN R.IsNonCash = 1 OR R.ReceiptTypeName = 'WaivedFromReceivableAdjustment'
				THEN ISNULL(uafr.TotalAmountApplied,0)
				ELSE 0
			END  AS Waived,
		R.NonCashReason,
		R.ReversalReason,
		ISNULL(CreditAppliedAmountsForReceipt.SumCreditApplied,0) AS CreditApplied,
		@CustomerNumber [CustomerNumber]
	INTO #Result
	FROM
		#ReceiptSummaries  R
		INNER JOIN #CreditAppliedAmountsForReceipt CreditAppliedAmountsForReceipt ON R.ReceiptID = CreditAppliedAmountsForReceipt.ReceiptID
		INNER JOIN #UpdateAmountForReceipts uafr ON R.ReceiptID = uafr.ReceiptID
	WHERE (( R.UnallocatedCashAmount != 0 AND R.ReceiptTypeName = 'WaivedFromReceivableAdjustment' )
		OR R.ReceiptTypeName != 'WaivedFromReceivableAdjustment')
		AND R.ReceiptTypeName !='PayDown'

	SELECT
		 #Result.ReceiptNumber
		,#Result.Currency
		,#Result.ReceivedDate
		,#Result.Status
		,#Result.PostDate
		,#Result.ReceiptTypeName
		,#Result.BatchName
		,#Result.CheckNumber
		,#Result.CheckAmount + ISNULL(#ReceiptRefunds.RefundAmount,0) CheckAmount
		,#Result.UnallocatedCashAmount UnallocatedCashAmount
		,#Result.AmountAppliedToCharges + ISNULL(#ReceiptRefunds.RefundAmount,0) AmountAppliedToCharges
		,#Result.AmountAppliedToTaxes
		,#Result.TotalAmountApplied + ISNULL(#ReceiptRefunds.RefundAmount,0) TotalAmountApplied
		,#Result.Id
		,#Result.Waived
		,#Result.NonCashReason
		,#Result.ReversalReason
		,#Result.CreditApplied
		,#Result.CustomerNumber
		,#Result.AdjustedWithHoldingTax
	FROM #Result
		LEFT JOIN #ReceiptRefunds ON #Result.Id = #ReceiptRefunds.ReceiptID
	WHERE #Result.CheckAmount !=0 OR #Result.UnallocatedCashAmount !=0
		OR #Result.AmountAppliedToCharges !=0 OR #Result.AmountAppliedToTaxes!=0
		OR #Result.TotalAmountApplied !=0 OR #Result.Waived !=0 OR #Result.CreditApplied !=0

	DROP TABLE #AccessibleLegalEntityIds
	DROP TABLE #EntityIds
	DROP TABLE #CreditAppliedAmountsForReceipt
	DROP TABLE #Receipts
	DROP TABLE #ReceiptSummaries
	DROP TABLE #Result
	DROP TABLE #InValidContractIds
	DROP TABLE #AllocatedReceiptDetails
	DROP TABLE #UnAllocatedReceiptDetails
	DROP TABLE #UpdateAmountForReceipts
	DROP TABLE #ReceiptRefunds
	DROP TABLE #ReceivableDetails
	DROP TABLE #CTE_ReceiptReceivableDetails
END

GO
