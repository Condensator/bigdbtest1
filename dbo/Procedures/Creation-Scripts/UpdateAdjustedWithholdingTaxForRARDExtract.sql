SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateAdjustedWithholdingTaxForRARDExtract] (@JobStepInstanceId BIGINT)
AS
BEGIN
	
	;WITH NonAccrualExcludedGroupNumbers AS(
		SELECT DISTINCT RPBF.GroupNumber from ReceiptPostByFileExcel_Extract RPBF
		WHERE RPBF.JobStepInstanceId=@JobStepInstanceId AND 
		(RPBF.NonAccrualCategory IS NULL OR RPBF.NonAccrualCategory NOT IN ('GroupedRentals','SingleWithRentals'))
	)
	SELECT
		RARDE.Id,
		RARDE.ReceivableDetailId,
		RARDE.AmountApplied,
		RARDE.LeaseComponentAmountApplied,
		RARDE.NonLeaseComponentAmountApplied,
		RDWTD.BasisAmount_Amount,
		RDWTD.Tax_Amount,
		RDWTD.EffectiveBalance_Amount WithHoldingEffectiveBalance_Amount,
		RD.EffectiveBalance_Amount ReceivableEffectiveBalance_Amount,
		SUM(RARDE.AmountApplied) OVER (PARTITION BY RARDE.ReceivableDetailId ORDER BY RARDE.Id) AS RunningAmountApplied,
		(SUM(RARDE.AmountApplied) OVER (PARTITION BY RARDE.ReceivableDetailId ORDER BY RARDE.Id) 
				- RARDE.AmountApplied) AS PreviousRunningAmountApplied,
		CAST(0.00 AS DECIMAL(16, 2)) AS AdjustedWithHoldingTax,
		CAST(0.00 AS DECIMAL(16, 2)) AS PreviousRunningAdjustedWithHoldingTax
	INTO #RARDExtract
	FROM ReceiptApplicationReceivableDetails_Extract RARDE
	INNER JOIN NonAccrualExcludedGroupNumbers NA ON RARDE.ReceiptId = NA.GroupNumber
	INNER JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON RARDE.ReceivableDetailId = RDWTD.ReceivableDetailId
	INNER JOIN ReceivableDetails RD ON RARDE.ReceivableDetailId = RD.Id
	WHERE RARDE.JobStepInstanceId = @JobStepInstanceId
	;

	with distinctcte as
	(
		select distinct ReceivableDetailId 
		from #RARDExtract
	)
	SELECT 
		RE.ReceivableDetailId,
		SUM(RARD.ReceivedTowardsInterest_Amount) AmountApplied_Amount
	INTO #PreviousRARD
	FROM distinctcte RE
	JOIN ReceiptApplicationReceivableDetails RARD ON RE.ReceivableDetailId = RARD.ReceivableDetailId
	JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
	JOIN Receipts R ON RA.ReceiptId = R.Id 
	WHERE R.Status IN ('Pending', 'ReadyForPosting', 'Posted', 'Completed')
	GROUP BY 
		RE.ReceivableDetailId
	;

	UPDATE #RARDExtract
		SET AdjustedWithHoldingTax =
				CASE
					WHEN ABS((RunningAmountApplied / (BasisAmount_Amount - Tax_Amount)) * Tax_Amount) > ABS(WithHoldingEffectiveBalance_Amount) THEN WithHoldingEffectiveBalance_Amount
					ELSE (AmountApplied / (BasisAmount_Amount - Tax_Amount)) * Tax_Amount
				END,
			PreviousRunningAdjustedWithHoldingTax = 
				CASE
					WHEN ABS((PreviousRunningAmountApplied / (BasisAmount_Amount - Tax_Amount)) * Tax_Amount) > ABS(WithHoldingEffectiveBalance_Amount) THEN WithHoldingEffectiveBalance_Amount
					ELSE (PreviousRunningAmountApplied / (BasisAmount_Amount - Tax_Amount)) * Tax_Amount
				END
	;
	UPDATE #RARDExtract
		SET AdjustedWithHoldingTax = 
				CASE WHEN AdjustedWithHoldingTax = WithHoldingEffectiveBalance_Amount THEN
						WithHoldingEffectiveBalance_Amount - PreviousRunningAdjustedWithHoldingTax
					 ELSE
						AdjustedWithHoldingTax
				END			
	;

	UPDATE ReceiptApplicationReceivableDetails_Extract
	SET
		AdjustedWithHoldingTax = RE.AdjustedWithHoldingTax,
		AmountApplied = 
			CASE
				WHEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax < RE.ReceivableEffectiveBalance_Amount THEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax
				ELSE RE.ReceivableEffectiveBalance_Amount
			END,
		LeaseComponentAmountApplied = 
			(CASE
				WHEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax < RE.ReceivableEffectiveBalance_Amount 
				THEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax
				ELSE RE.ReceivableEffectiveBalance_Amount
			END) * RARDE.LeaseComponentAmountApplied / RARDE.AmountApplied,
		NonLeaseComponentAmountApplied = 
			(CASE
				WHEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax < RE.ReceivableEffectiveBalance_Amount 
				THEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax
				ELSE RE.ReceivableEffectiveBalance_Amount
			END) * RARDE.NonLeaseComponentAmountApplied / RARDE.AmountApplied,
		BookAmountApplied =
			CASE
				--For Cash Accrual Loans, Book Amount Applied will be non-zero and equal to the Updated Amount Applied 
				--If ((ReceivableType is 'LoanInterest' or 'LoanPrincipal') AND (IncomeType is not 'InterimInterest' and not 'TakeDownInterest'))
				WHEN RARDE.BookAmountApplied != 0 THEN
					CASE
						WHEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax < RE.ReceivableEffectiveBalance_Amount THEN RARDE.AmountApplied + RE.AdjustedWithHoldingTax
						ELSE RE.ReceivableEffectiveBalance_Amount
					END
					ELSE 0.0
				END
	FROM ReceiptApplicationReceivableDetails_Extract RARDE
	JOIN #RARDExtract RE ON RARDE.Id = RE.Id

END

GO
