SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceiptSummariesForContractService]
(
	@ContractSequenceNumber NVARCHAR(80),
	@FilterCustomerId		BIGINT = NULL
)
AS
SET NOCOUNT ON
BEGIN
	DECLARE @ContractId		BIGINT
	DECLARE @CustomerId		BIGINT
	DECLARE @ContractType	NVARCHAR(MAX)
	DECLARE @PartyNumber	NVARCHAR(MAX)

	SELECT @ContractId = Id , @ContractType = ContractType FROM Contracts WHERE SequenceNumber=@ContractSequenceNumber

	CREATE TABLE #AllocatedReceipts
	(
		ReceiptId				BIGINT,
		Number					NVARCHAR(40),
		EntityType				NVARCHAR(20),
		PartyNumber				NVARCHAR(40),
		Receipt_Amount			DECIMAL(16,2),
		Balance_Amount			DECIMAL(16,2),
		ReceiptClassification	NVARCHAR(46)
	)
	CREATE TABLE #ReceivableDetail
	(
	 ReceivableDetailId BIGINT,
	 CustomerId BIGINT
	)

	IF @ContractType = 'Lease'
	BEGIN
		SELECT @CustomerId = CustomerId FROM LeaseFinances WHERE ContractId = @ContractId AND IsCurrent = 1
		SELECT @PartyNumber = PartyNumber FROM Parties WHERE Id = @CustomerId
	END
	ELSE
	BEGIN
		SELECT @CustomerId = CustomerId FROM LoanFinances WHERE ContractId = @ContractId AND IsCurrent = 1
		SELECT @PartyNumber = PartyNumber FROM Parties WHERE Id = @CustomerId
	END
	IF (@FilterCustomerId IS NOT NULL)
	BEGIN
	INSERT INTO #ReceivableDetail
	SELECT RD.Id ReceivableDetailId,R.CustomerId
	FROM ReceivableDetails RD
	JOIN Receivables R ON RD.ReceivableId = R.Id
		AND R.IsActive = 1 AND RD.IsActive = 1
	WHERE EntityId = @ContractId AND EntityType = 'CT'
		AND  R.CustomerId = @FilterCustomerId
	END
	ELSE 
	BEGIN
	INSERT INTO #ReceivableDetail
	SELECT RD.Id ReceivableDetailId,R.CustomerId
	FROM ReceivableDetails RD
	JOIN Receivables R ON RD.ReceivableId = R.Id
		AND R.IsActive = 1 AND RD.IsActive = 1
	WHERE EntityId = @ContractId AND EntityType = 'CT'
	END

	SELECT
		Receipts.Id,#ReceivableDetail.CustomerId,RT.ReceiptTypeName
		,SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) AS ReceivedAmount_Amount 
		,SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied_Amount
		,SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied_Amount
		,SUM(ReceiptApplicationReceivableDetails.AdjustedWithHoldingTax_Amount) AS AdjustedWithHoldingTax_Amount 
		,SUM(ReceiptApplications.CreditApplied_Amount) AS CreditApplied_Amount
		,ReceiptApplicationReceivableDetails.ReceivableDetailId
		INTO #RARDToSelect
	FROM Receipts
		JOIN ReceiptTypes AS RT ON Receipts.TypeId = RT.Id 
		JOIN ReceiptApplications ON Receipts.Id = ReceiptApplications.ReceiptId
		JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
			AND ReceiptApplicationReceivableDetails.IsActive = 1
		JOIN #ReceivableDetail ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetail.ReceivableDetailId
	GROUP BY Receipts.Id,#ReceivableDetail.CustomerId ,RT.ReceiptTypeName,ReceiptApplicationReceivableDetails.ReceivableDetailId

	INSERT INTO #RARDToSelect 
	SELECT
		Receipts.Id,#ReceivableDetail.CustomerId,RT.ReceiptTypeName,
		ISNULL(SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount), 0.0) AS ReceivedAmount_Amount, 
		ISNULL(SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount),0.0) AS AmountApplied_Amount
		,ISNULL(SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount), 0.0) AS TaxApplied_Amount
		,ISNULL(SUM(ReceiptApplicationReceivableDetails.AdjustedWithHoldingTax_Amount) , 0.0) AS AdjustedWithHoldingTax_Amount 
		,ISNULL(SUM(ReceiptApplications.CreditApplied_Amount), 0.0) AS CreditApplied_Amount
		,ReceiptApplicationReceivableDetails.ReceivableDetailId
	FROM Receipts
		JOIN ReceiptTypes AS RT ON Receipts.TypeId = RT.Id 
		JOIN ReceiptApplications ON Receipts.Id = ReceiptApplications.ReceiptId
		LEFT JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
			AND ReceiptApplicationReceivableDetails.IsActive = 1
		LEFT JOIN #ReceivableDetail ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetail.ReceivableDetailId
	WHERE #ReceivableDetail.ReceivableDetailId IS NULL AND Receipts.ContractId = @ContractId
	GROUP BY Receipts.Id,#ReceivableDetail.CustomerId ,RT.ReceiptTypeName,ReceiptApplicationReceivableDetails.ReceivableDetailId

	SELECT Id,ReceiptTypeName,CustomerId INTO #ReceiptsToSelect FROM #RARDToSelect GROUP BY Id,ReceiptTypeName,CustomerId

	SELECT Id,ReceiptTypeName INTO #ReceiptIds FROM #ReceiptsToSelect GROUP BY Id,ReceiptTypeName

	IF(@FilterCustomerId IS NULL)
	BEGIN
	INSERT INTO #ReceiptIds
	SELECT Receipts.Id,RT.ReceiptTypeName FROM Receipts 
	JOIN ReceiptTypes AS RT ON Receipts.TypeId = RT.Id 
	JOIN ReceiptAllocations RA on Ra.Receiptid = Receipts.Id
	LEFT JOIN #ReceiptIds R ON Receipts.Id= R.Id
	WHERE Receipts.ContractId = @ContractId
	AND R.Id IS NULL AND RA.EntityType ='UnAllocated' AND RA.AllocationAmount_Amount -RA.AmountApplied_Amount >0
	AND Receipts.ReceiptAmount_Amount = Balance_Amount
	GROUP BY Receipts.Id,RT.ReceiptTypeName
	END;

	SELECT
		SUM(RA.CreditApplied_Amount) AS SumCreditApplied
		,RA.ReceiptId
	INTO #CreditAmount
	FROM ReceiptApplications AS RA 
	JOIN #ReceiptIds R ON Ra.ReceiptId = R.Id 
	GROUP BY RA.ReceiptId

	SELECT 
		Receipts.Id ReceiptId
		,Receipts.Number Number
		,@PartyNumber PartyNumber
		,Receipts.ReceiptAmount_Amount + ISNULL(CreditAmount.SumCreditApplied,0) ReceiptAmount_Amount
		,Receipts.Balance_Amount
		,Receipts.Status
	INTO #UnAllocatedReceiptsInfo
	FROM Receipts
		INNER JOIN #ReceiptIds ON #ReceiptIds.Id = Receipts.Id
		LEFT JOIN #CreditAmount CreditAmount ON Receipts.Id = CreditAmount.ReceiptId
		LEFT JOIN UnappliedReceipts ON Receipts.Id = UnappliedReceipts.ReceiptId
			AND UnappliedReceipts.IsActive = 1
	WHERE ContractId = @ContractId
		AND ((Receipts.ReceiptAmount_Amount + ISNULL(CreditAmount.SumCreditApplied,0) + ISNULL(UnappliedReceipts.AmountApplied_Amount,0)  = Balance_Amount))
		AND ( Receipts.Balance_Amount != 0 AND #ReceiptIds.ReceiptTypeName = 'WaivedFromReceivableAdjustment' )
		AND #ReceiptIds.ReceiptTypeName != 'PayDown'

	SELECT
		#UnAllocatedReceiptsInfo.ReceiptId
		,SUM(UnallocatedRefundDetails.AmountToBeCleared_Amount) RefundAmount
	INTO #TempReceiptRefunds
	FROM UnallocatedRefundDetails
		JOIN UnallocatedRefunds ON UnallocatedRefundDetails.UnallocatedRefundId = UnallocatedRefunds.Id AND UnallocatedRefunds.Status='Approved'
		JOIN ReceiptAllocations ON UnallocatedRefundDetails.ReceiptAllocationId = ReceiptAllocations.Id
		JOIN #UnAllocatedReceiptsInfo ON ReceiptAllocations.ReceiptId = #UnAllocatedReceiptsInfo.ReceiptId
	GROUP BY #UnAllocatedReceiptsInfo.ReceiptId

	SELECT
		#UnAllocatedReceiptsInfo.*
	INTO #UnAllocatedReceipts
	FROM #UnAllocatedReceiptsInfo
		LEFT JOIN #TempReceiptRefunds ON #UnAllocatedReceiptsInfo.ReceiptId = #TempReceiptRefunds.ReceiptId
			AND ((#UnAllocatedReceiptsInfo.ReceiptAmount_Amount = #UnAllocatedReceiptsInfo.Balance_Amount + ISNULL(#TempReceiptRefunds.RefundAmount,0)
					AND #UnAllocatedReceiptsInfo.Balance_Amount + ISNULL(#TempReceiptRefunds.RefundAmount,0) >0))


	INSERT INTO #AllocatedReceipts(ReceiptId,Number,EntityType,PartyNumber,Receipt_Amount,Balance_Amount,ReceiptClassification)
	(
		SELECT
			DISTINCT
			Receipts.Id,
			Receipts.Number,
			Receipts.EntityType,
			P.PartyNumber,
			Receipts.ReceiptAmount_Amount,
			Receipts.Balance_Amount,
			Receipts.ReceiptClassification
		FROM Receipts
			INNER JOIN #ReceiptsToSelect ON #ReceiptsToSelect.Id = Receipts.Id
			LEFT JOIN  Parties P ON #ReceiptsToSelect.CustomerId = P.Id
		WHERE (( Receipts.Balance_Amount != 0 AND #ReceiptsToSelect.ReceiptTypeName = 'WaivedFromReceivableAdjustment' )
			OR #ReceiptsToSelect.ReceiptTypeName != 'WaivedFromReceivableAdjustment')
			AND #ReceiptsToSelect.ReceiptTypeName != 'PayDown'
			AND Receipts.Id NOT IN (SELECT ReceiptId FROM #UnAllocatedReceipts)
	)

	INSERT INTO #AllocatedReceipts(ReceiptId,Number,EntityType,PartyNumber,Receipt_Amount,Balance_Amount,ReceiptClassification)
	(
		SELECT
			DISTINCT
			Receipts.Id,
			Receipts.Number,
			Receipts.EntityType,
			@PartyNumber PartyNumber,
			Receipts.ReceiptAmount_Amount,
			Receipts.Balance_Amount,
			Receipts.ReceiptClassification
		FROM Receipts
			INNER JOIN ReceiptTypes AS RT ON Receipts.TypeId = RT.Id
				
		WHERE Receipts.ContractId = @ContractId
			AND RT.ReceiptTypeName = 'EscrowRefund'
			AND Receipts.Id NOT IN (SELECT ReceiptId FROM #AllocatedReceipts)
	)

	CREATE TABLE #CreditAppliedAmountsForReceipt(SumCreditApplied DECIMAL(16,2),ReceiptId BIGINT,PartyNumber  NVARCHAR(40))

	INSERT INTO #CreditAppliedAmountsForReceipt(SumCreditApplied,ReceiptId,PartyNumber)
	SELECT
		SUM(RA.CreditApplied_Amount) AS SumCreditApplied
		,R.ReceiptId
		,R.PartyNumber
	FROM #AllocatedReceipts AS R
		JOIN ReceiptApplications AS RA ON R.ReceiptId = RA.ReceiptId
	GROUP BY R.ReceiptId,R.PartyNumber

	SELECT
		 R.ReceiptId
		,SUM(URD.AmountToBeCleared_Amount) RefundAmount
	INTO #ReceiptRefunds
	FROM UnallocatedRefundDetails AS URD
		JOIN UnallocatedRefunds ON URD.UnallocatedRefundId = UnallocatedRefunds.Id AND UnallocatedRefunds.Status='Approved'
		JOIN ReceiptAllocations AS RA ON URD.ReceiptAllocationId = RA.Id
		JOIN #AllocatedReceipts AS R ON RA.ReceiptId = R.ReceiptId
	GROUP BY R.ReceiptId

SELECT * INTO #AppliedAmountsForReceipt FROM 
	(
	SELECT
		 SUM(AmountAppliedForCharges) AmountAppliedForCharges
		,SUM(AmountAppliedForTax) AmountAppliedForTax
		,SUM(TotalAmountApplied) TotalAmountApplied
		,SUM(CreditApplied) AS CreditApplied
		,ReceiptId
		,SUM(AdjustedWithHoldingTax) AS AdjustedWithHoldingTax
		,PartyNumber FROM
		(
			SELECT
				 CASE
					WHEN (R.ReceiptClassification = 'Cash' OR R.ReceiptClassification = 'NonCash')
						THEN SUM(RD.ReceivedAmount_Amount)
						ELSE SUM(RD.AmountApplied_Amount + RD.TaxApplied_Amount) END
					AS AmountAppliedForCharges
				,SUM(RD.TaxApplied_Amount) AmountAppliedForTax
				,SUM(RD.AmountApplied_Amount + RD.TaxApplied_Amount) TotalAmountApplied
				,SUM(RD.CreditApplied_Amount) AS CreditApplied
				,SUM(RD.AdjustedWithHoldingTax_Amount) AS AdjustedWithHoldingTax
				,R.ReceiptId
				,R.PartyNumber
			FROM #AllocatedReceipts AS R
				JOIN #RARDToSelect RD on R.ReceiptId = RD.Id
			GROUP BY R.ReceiptId,R.PartyNumber,R.EntityType,R.ReceiptClassification,RD.ReceivableDetailId
			HAVING (SUM(RD.AmountApplied_Amount)+SUM(RD.TaxApplied_Amount)) > 0
				OR ((SUM(RD.AmountApplied_Amount)+SUM(RD.TaxApplied_Amount)) = 0 AND MIN(R.Receipt_Amount) = MIN(R.Balance_Amount) AND r.EntityType != 'Customer' AND r.EntityType !=  '_')
		) AmountsGroupedByReceivableDetail
		GROUP BY ReceiptId,PartyNumber
	UNION
		SELECT
			CASE
				WHEN (R.ReceiptClassification = 'Cash' OR R.ReceiptClassification = 'NonCash')
					THEN SUM(RAD.ReceivedAmount_Amount)
					ELSE SUM(RAD.AmountApplied_Amount) END
				AS AmountAppliedForCharges,
			0.00 AS AmountAppliedToTaxes,
			SUM(RAD.AmountApplied_Amount) AS TotalAmountApplied,
			SUM(RAp.CreditApplied_Amount) AS CreditApplied,
			SUM(RAD.AdjustedWithHoldingTax_Amount)  AS AdjustedWithHoldingTax,
			R.ReceiptID,
			R.PartyNumber
		FROM #AllocatedReceipts R
			JOIN Receipts ON R.ReceiptId = Receipts.Id
			JOIN ReceiptTypes AS RT ON Receipts.TypeId = RT.Id
			JOIN ReceiptApplications RAp ON R.ReceiptID = RAp.ReceiptId
				AND RT.ReceiptTypeName = 'EscrowRefund'
			JOIN ReceiptApplicationReceivableDetails AS RAD ON RAp.Id = RAD.ReceiptApplicationId
				AND RAD.IsActive = 1
		GROUP BY R.ReceiptID,R.PartyNumber,R.ReceiptClassification
	) AS T
	SELECT
			 R.Number ReceiptNumber
			,CC.ISO Currency
			,R.ReceivedDate ReceivedDate
			,R.Status Status
			,R.PostDate PostDate
			,RT.ReceiptTypeName ReceiptTypeName
			,RB.Name BatchName
			,CASE
				WHEN ((R.EntityType = 'Lease' OR R.EntityType = 'Loan' OR R.EntityType = 'LeveragedLease' ) AND R.ContractId <> @ContractId)
					THEN  0
					ELSE R.Balance_Amount
				END AS UnallocatedCashAmount
			,R.CheckNumber CheckNumber
			,CASE
				WHEN R.ReceiptClassification <> 'NonCash' AND RT.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'	THEN
				(
					CASE
						WHEN((R.EntityType = 'Lease' OR R.EntityType = 'Loan' OR R.EntityType = 'LeveragedLease')AND R.ContractId <> @ContractId) OR R.EntityType = '_'
							THEN
								ISNULL(CAST((AAR.TotalAmountApplied + ISNULL(#ReceiptRefunds.RefundAmount,0)) AS DECIMAL(16,2)),0)
							ELSE
								ISNULL(CAST((AAR.TotalAmountApplied + ISNULL(#ReceiptRefunds.RefundAmount,0)) AS DECIMAL(16,2)),0) + R.Balance_Amount  - ISNULL	(CreditAppliedAmount.SumCreditApplied,0)

					END
				)
				ELSE 0 END CheckAmount
			,CASE
				WHEN R.ReceiptClassification <> 'NonCash' AND RT.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'
					THEN ISNULL(CAST((AAR.AmountAppliedForCharges + ISNULL(#ReceiptRefunds.RefundAmount,0)) AS DECIMAL(16,2)),0)
					ELSE 0
				END AS  AmountAppliedToCharges
			,CASE
				WHEN R.ReceiptClassification <> 'NonCash' AND RT.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'
					THEN ISNULL(CAST(AAR.AmountAppliedForTax AS DECIMAL(16,2)),0)
					ELSE 0
				END AS AmountAppliedToTaxes
			,CASE
				WHEN R.ReceiptClassification <> 'NonCash' AND RT.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'
					THEN ISNULL(CAST((AAR.TotalAmountApplied + ISNULL(#ReceiptRefunds.RefundAmount,0)) AS DECIMAL(16,2)),0)
					ELSE 0
				END AS  TotalAmountApplied
			,CASE
				WHEN R.ReceiptClassification = 'NonCash' OR RT.ReceiptTypeName = 'WaivedFromReceivableAdjustment' OR R.ReceiptClassification =  'NonAccrualNonDSLNonCash'
					THEN	ISNULL(CAST(AAR.TotalAmountApplied AS DECIMAL(16,2)),0)
					ELSE 0
				END Waived
			,COALESCE(R.NonCashReason,'_') NonCashReason
			,R.Id
			,RRR.Code [ReversalReason]
			,ISNULL(CreditAppliedAmount.SumCreditApplied,0) AS CreditApplied
			,AR.PartyNumber [CustomerNumber]
			,ISNULL(AAR.AdjustedWithHoldingTax, 0.0) AS AdjustedWithHoldingTax
		FROM #AllocatedReceipts AS AR
		INNER JOIN Receipts AS R ON AR.ReceiptId = R.Id
			INNER JOIN Currencies AS C ON C.Id = R.CurrencyId
			INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
			INNER JOIN ReceiptTypes AS RT ON R.TypeId = RT.Id 
			LEFT JOIN #CreditAppliedAmountsForReceipt CreditAppliedAmount ON AR.ReceiptId = CreditAppliedAmount.ReceiptId
				AND AR.PartyNumber = CreditAppliedAmount.PartyNumber
			LEFT JOIN #AppliedAmountsForReceipt AS AAR ON AAR.ReceiptId = R.Id
				AND AAR.PartyNumber = AR.PartyNumber
			LEFT JOIN ReceiptReversalReasons RRR ON R.ReversalReasonId = RRR.Id
			LEFT JOIN ReceiptBatches AS RB ON RB.Id = R.ReceiptBatchId
			LEFT JOIN #ReceiptRefunds ON AR.ReceiptId = #ReceiptRefunds.ReceiptId
	UNION
		SELECT
			R.Number ReceiptNumber
			,CC.ISO Currency
			,R.ReceivedDate ReceivedDate
			,R.Status Status
			,R.PostDate PostDate
			,RT.ReceiptTypeName ReceiptTypeName
			,RB.Name BatchName
			,R.Balance_Amount AS UnallocatedCashAmount
			,R.CheckNumber CheckNumber
			,CASE
				WHEN R.ReceiptClassification <> 'NonCash' AND RT.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' AND R.ReceiptClassification <>  'NonAccrualNonDSLNonCash'
					THEN R.ReceiptAmount_Amount
					ELSE 0
				END AS CheckAmount
			,ISNULL(#TempReceiptRefunds.RefundAmount,0) AmountAppliedToCharges
			,0 AmountAppliedToTaxes
			,ISNULL(#TempReceiptRefunds.RefundAmount,0) TotalAmountApplied
			,CASE
				WHEN R.ReceiptClassification = 'NonCash' OR RT.ReceiptTypeName = 'WaivedFromReceivableAdjustment' OR R.ReceiptClassification =  'NonAccrualNonDSLNonCash'
					THEN	R.ReceiptAmount_Amount
					ELSE 0
				END AS  Waived
			,COALESCE(R.NonCashReason,'_') NonCashReason
			,R.Id
			,RRR.Code [ReversalReason]
			,0 CreditApplied
			,#UnAllocatedReceipts.PartyNumber [CustomerNumber]
			,0 AdjustedWithHoldingTax
		FROM #UnAllocatedReceipts
			JOIN Receipts R ON #UnAllocatedReceipts.ReceiptId = R.Id
			INNER JOIN Currencies AS C ON C.Id = R.CurrencyId
			INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
			INNER JOIN ReceiptTypes AS RT ON R.TypeId = RT.Id
			LEFT JOIN ReceiptReversalReasons RRR ON R.ReversalReasonId = RRR.Id
			LEFT JOIN ReceiptBatches AS RB ON RB.Id = R.ReceiptBatchId
			LEFT JOIN #TempReceiptRefunds ON #UnAllocatedReceipts.ReceiptId = #TempReceiptRefunds.ReceiptId


	DROP TABLE #AllocatedReceipts
	DROP TABLE #CreditAppliedAmountsForReceipt
	DROP TABLE #UnAllocatedReceipts
	DROP TABLE #ReceiptRefunds
	DROP TABLE #TempReceiptRefunds
	DROP TABLE #UnAllocatedReceiptsInfo
	DROP TABLE #ReceiptsToSelect
	DROP TABLE #ReceivableDetail
	DROP TABLE #ReceiptIds
	DROP TABLE #AppliedAmountsForReceipt
	DROP TABLE #CreditAmount
	DROP TABLE #RARDToSelect
END

GO
