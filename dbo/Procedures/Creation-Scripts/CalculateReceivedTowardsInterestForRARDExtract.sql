SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CalculateReceivedTowardsInterestForRARDExtract] 
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN
	
	SELECT
		RARDE.Id,
		RARDE.ReceivableDetailId,
		(RARDE.AmountApplied - RARDE.AdjustedWithHoldingTax) AmountApplied,
		(RDWTD.BasisAmount_Amount - RDWTD.Tax_Amount) WHTAmount,
		SUM((RARDE.AmountApplied - RARDE.AdjustedWithHoldingTax)) OVER (PARTITION BY RARDE.ReceivableDetailId ORDER BY RARDE.Id) AS RunningAmountApplied,
		(SUM((RARDE.AmountApplied - RARDE.AdjustedWithHoldingTax)) OVER (PARTITION BY RARDE.ReceivableDetailId ORDER BY RARDE.Id) - 
			(RARDE.AmountApplied - RARDE.AdjustedWithHoldingTax)) AS PreviousRunningAmountApplied,
		CAST(0.00 AS DECIMAL(16, 2)) AS TotalReceivedTowardsInterestAmount,
		CAST(0.00 AS DECIMAL(16, 2)) AS ReceivedTowardsInterestAmount
	INTO #RARDExtract
	FROM ReceiptApplicationReceivableDetails_Extract RARDE
	INNER JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON RARDE.ReceivableDetailId = RDWTD.ReceivableDetailId
	INNER JOIN ReceivableDetails RD ON RARDE.ReceivableDetailId = RD.Id
	WHERE RARDE.JobStepInstanceId = @JobStepInstanceId
	;
	SELECT 
		RE.ReceivableDetailId,
		SUM(RARD.ReceivedTowardsInterest_Amount) TotalReceivedTowardsInterestAmount
	INTO #PreviousRARD
	FROM #RARDExtract RE
	JOIN ReceiptApplicationReceivableDetails RARD ON RE.ReceivableDetailId = RARD.ReceivableDetailId
	JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
	JOIN Receipts R ON RA.ReceiptId = R.Id 
	WHERE R.Status IN ('Pending', 'ReadyForPosting', 'Posted', 'Completed')
	GROUP BY 
		RE.ReceivableDetailId
	;
	UPDATE RE
		SET RE.TotalReceivedTowardsInterestAmount = ISNULL(PR.TotalReceivedTowardsInterestAmount, 0.00)
	FROM #RARDExtract RE
	LEFT JOIN #PreviousRARD PR ON RE.ReceivableDetailId = PR.ReceivableDetailId
	;
	UPDATE #RARDExtract
		SET ReceivedTowardsInterestAmount = CASE WHEN TotalReceivedTowardsInterestAmount = WHTAmount 
													THEN 0.00
												 WHEN (RunningAmountApplied + TotalReceivedTowardsInterestAmount) > WHTAmount THEN
													CASE WHEN (PreviousRunningAmountApplied + TotalReceivedTowardsInterestAmount) > WHTAmount THEN
														0.00
													ELSE
														WHTAmount - PreviousRunningAmountApplied - TotalReceivedTowardsInterestAmount
													END
												 ELSE
													AmountApplied
											 END
	;
	UPDATE ReceiptApplicationReceivableDetails_Extract
	SET
		ReceivedTowardsInterest =  RE.ReceivedTowardsInterestAmount
	FROM ReceiptApplicationReceivableDetails_Extract RARDE
	JOIN #RARDExtract RE ON RARDE.Id = RE.Id

END

GO
