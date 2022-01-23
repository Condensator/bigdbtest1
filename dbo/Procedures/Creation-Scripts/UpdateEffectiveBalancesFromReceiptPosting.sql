SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEffectiveBalancesFromReceiptPosting]
(
@ReceiptApplicationInfo [ReceiptApplicationInfo] READONLY,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET,
@IsReceiptApplication BIT = 0,
@IsOverApplicationExist BIT OUTPUT
)
AS
BEGIN
SET NOCOUNT ON;

	CREATE TABLE #ReceiptApplicationInfo
	(
		ReceiptId BIGINT,
		ApplicationId BIGINT,
		ReceivedDate DATE
	);

	CREATE TABLE #AppliedReceivableDetailInfo
	(
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT PRIMARY KEY CLUSTERED,
		AmountApplied DECIMAL(16,2) NOT NULL,
		TaxApplied DECIMAL(16,2) NOT NULL,
		BookAmountApplied DECIMAL(16,2) NOT NULL,
		PreviousBookAmountApplied DECIMAL(16,2) NOT NULL,
		PreviousAmountApplied DECIMAL(16,2) NOT NULL,
		PreviousTaxApplied DECIMAL(16,2) NOT NULL,
		AdjustedWithHoldingTax DECIMAL(16,2) NULL,
		PreviousAdjustedWithHoldingTax DECIMAL(16,2) NULL,
		ReceivableInvoiceId BIGINT NULL
	);

	CREATE NONCLUSTERED INDEX IX_ReceivableId
    ON #AppliedReceivableDetailInfo (ReceivableId);

	CREATE TABLE #ReceiptAppReceivableTaxDetails
	(
		Id BIGINT,
		ReceiptApplicationId BIGINT,
		ReceivedDate DATE,
		ReceivableDetailId BIGINT,
		TaxApplied DECIMAL(16,2),
		PreviousTaxApplied DECIMAL(16,2),
		RunningTaxApplied DECIMAL(16,2),
		IsReApplication bit
	);	

	CREATE TABLE #ReceiptAppReceivableTaxImpositions
	(
		Id BIGINT,
		RARDId BIGINT,
		ReceivableDetailId BIGINT,
		ReceiptApplicationId BIGINT,
		TaxApplied DECIMAL(16,2),
		RunningTaxApplied DECIMAL(16,2),
		TaxImpositionId BIGINT,
		EffectiveTaxBalance DECIMAL(16,2),
		RunningEffectiveBalance DECIMAL(16,2),
		ImpositionTaxToApply DECIMAL(16,2),
		RunningImpositionTaxApplied DECIMAL(16,2),
		PreviousImpositionTaxApplied DECIMAL(16,2),
		TaxDetailId BIGINT,
		ReceivableTaxId BIGINT,
		Currency NVARCHAR(6)
	);
		
	CREATE TABLE #PrevReceiptAppReceivableTaxImpositions
	(
		ReceivableTaxImpositionId BIGINT,
		PrevPostedAmount DECIMAL(16, 2),
		IsReApplication BIT 
	)

	INSERT INTO #ReceiptApplicationInfo(ReceiptId,ApplicationId,ReceivedDate)
	SELECT ReceiptId,ApplicationId,ReceivedDate FROM @ReceiptApplicationInfo;

	IF (@IsReceiptApplication = 1)
	BEGIN

		INSERT INTO #ReceiptAppReceivableTaxDetails
		SELECT 
			ReceiptApplicationReceivableDetails.Id,
			ReceiptApplicationId,
			ReceivedDate,
			ReceivableDetailId,
			TaxApplied_Amount TaxApplied,
			PreviousTaxApplied_Amount PreviousTaxApplied,
			SUM(TaxApplied_Amount) OVER (PARTITION BY ReceivableDetailId ORDER BY ReceiptId, ReceivedDate) AS RunningTaxApplied
			,ReceiptApplicationReceivableDetails.IsReApplication
		FROM #ReceiptApplicationInfo
		JOIN ReceiptApplicationReceivableDetails ON #ReceiptApplicationInfo.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		AND ReceiptApplicationReceivableDetails.IsActive=1
					
		INSERT INTO #PrevReceiptAppReceivableTaxImpositions
		SELECT RTI.Id, SUM(RART.AmountPosted_Amount), 1 IsReApplication
		FROM ReceiptApplicationReceivableTaxImpositions RART
		JOIN ReceiptApplications RA ON RART.ReceiptApplicationId = RA.Id
		JOIN ReceivableTaxImpositions RTI ON RART.ReceivableTaxImpositionId = RTI.Id
		JOIN ReceivableTaxDetails RTD ON RTI.ReceivableTaxDetailId = RTD.Id AND RTD.IsActive = 1
		JOIN #ReceiptAppReceivableTaxDetails RARTD ON RARTD.ReceivableDetailId = RTD.ReceivableDetailId AND RARTD.IsReApplication = 1
		JOIN #ReceiptApplicationInfo ON #ReceiptApplicationInfo.ReceiptId = RA.ReceiptId AND #ReceiptApplicationInfo.ApplicationId <> RA.Id
		GROUP BY RTI.Id


		UPDATE ReceiptApplicationReceivableDetails  
		SET AmountApplied_Amount = AmountApplied_Amount - PreviousAmountApplied_Amount,
			PreviousAmountApplied_Amount = 0,
			TaxApplied_Amount = TaxApplied_Amount - PreviousTaxApplied_Amount,
			PreviousTaxApplied_Amount = 0,
			LeaseComponentAmountApplied_Amount = LeaseComponentAmountApplied_Amount - PrevLeaseComponentAmountApplied_Amount,
			NonLeaseComponentAmountApplied_Amount = NonLeaseComponentAmountApplied_Amount - PrevNonLeaseComponentAmountApplied_Amount,
			PrevLeaseComponentAmountApplied_Amount = 0,
			PrevNonLeaseComponentAmountApplied_Amount = 0,
			BookAmountApplied_Amount = BookAmountApplied_Amount - PreviousBookAmountApplied_Amount,
			PreviousBookAmountApplied_Amount = 0,
			AdjustedWithholdingTax_Amount = AdjustedWithholdingTax_Amount - PreviousAdjustedWithHoldingTax_Amount,
			PreviousAdjustedWithHoldingTax_Amount = 0,
			ReceivedAmount_Amount = (AmountApplied_Amount - PreviousAmountApplied_Amount) - (AdjustedWithholdingTax_Amount - PreviousAdjustedWithHoldingTax_Amount)
		FROM ReceiptApplicationReceivableDetails
		JOIN #ReceiptApplicationInfo ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId
				
		UPDATE ReceiptApplicationInvoices
		SET AmountApplied_Amount = AmountApplied_Amount - PreviousAmountApplied_Amount,
			PreviousAmountApplied_Amount = 0,
			TaxApplied_Amount = TaxApplied_Amount - PreviousTaxApplied_Amount,
			PreviousTaxApplied_Amount = 0
		FROM ReceiptApplicationInvoices
		JOIN #ReceiptApplicationInfo ON ReceiptApplicationInvoices.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId		

		UPDATE ReceiptApplicationReceivableGroups
		SET AmountApplied_Amount = AmountApplied_Amount - PreviousAmountApplied_Amount,
		TaxApplied_Amount = TaxApplied_Amount - PreviousTaxApplied_Amount,
		PreviousAmountApplied_Amount = 0,
		PreviousTaxApplied_Amount = 0,
		BookAmountApplied_Amount = BookAmountApplied_Amount - PreviousBookAmountApplied_Amount,
		PreviousBookAmountApplied_Amount = 0
		FROM ReceiptApplicationReceivableGroups
		JOIN #ReceiptApplicationInfo ON ReceiptApplicationReceivableGroups.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId

	END

	INSERT INTO #AppliedReceivableDetailInfo(ReceivableId,ReceivableDetailId,AmountApplied,TaxApplied,BookAmountApplied,PreviousBookAmountApplied,PreviousAmountApplied,PreviousTaxApplied,AdjustedWithHoldingTax,PreviousAdjustedWithHoldingTax)
	SELECT 
		ReceivableId,
		ReceivableDetailId,
		SUM(AmountApplied_Amount) AmountApplied,
		SUM(TaxApplied_Amount) TaxApplied,
		SUM(BookAmountApplied_Amount) BookAmountApplied,
		SUM(PreviousBookAmountApplied_Amount) PreviousBookAmountApplied,
		SUM(PreviousAmountApplied_Amount) PreviousAmountApplied,
		SUM(PreviousTaxApplied_Amount) PreviousTaxApplied,
		SUM(AdjustedWithholdingTax_Amount) AdjustedWithHoldingTax,
		SUM(PreviousAdjustedWithHoldingTax_Amount) PreviousAdjustedWithHoldingTax
	FROM #ReceiptApplicationInfo ReceiptApplication
	JOIN ReceiptApplicationReceivableDetails ON ReceiptApplication.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND ReceiptApplicationReceivableDetails.IsActive=1
	JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
	GROUP BY ReceivableDetailId,ReceivableDetails.ReceivableId;

	--Check for RARD.IsActive=0
	INSERT INTO #AppliedReceivableDetailInfo(ReceivableId,ReceivableDetailId,AmountApplied,TaxApplied,BookAmountApplied,PreviousBookAmountApplied,PreviousAmountApplied,PreviousTaxApplied,AdjustedWithHoldingTax,PreviousAdjustedWithHoldingTax)
	SELECT 
		ReceivableId,
		ReceivableDetailId,
		SUM(AmountApplied_Amount) AmountApplied,
		SUM(TaxApplied_Amount) TaxApplied,
		SUM(BookAmountApplied_Amount) BookAmountApplied,
		SUM(PreviousBookAmountApplied_Amount) PreviousBookAmountApplied,
		SUM(PreviousAmountApplied_Amount) PreviousAmountApplied,
		SUM(PreviousTaxApplied_Amount) PreviousTaxApplied,
		SUM(AdjustedWithholdingTax_Amount) AdjustedWithHoldingTax,
		SUM(PreviousAdjustedWithHoldingTax_Amount) PreviousAdjustedWithHoldingTax
	FROM #ReceiptApplicationInfo ReceiptApplication
	JOIN ReceiptApplicationReceivableDetails ON ReceiptApplication.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND ReceiptApplicationReceivableDetails.IsActive=0 AND (PreviousAmountApplied_Amount <> 0 OR PreviousTaxApplied_Amount <> 0 OR PreviousBookAmountApplied_Amount <> 0)
	JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
	GROUP BY ReceivableDetailId,ReceivableDetails.ReceivableId;

	-- Receivable Details 

	SET @IsOverApplicationExist = 0

	CREATE TABLE #ReceivableDetailsInfo (Amount DECIMAL, Balance DECIMAL)

	UPDATE ReceivableDetails 
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount + #AppliedReceivableDetailInfo.PreviousAmountApplied - #AppliedReceivableDetailInfo.AmountApplied,
		EffectiveBookBalance_Amount = EffectiveBookBalance_Amount + #AppliedReceivableDetailInfo.PreviousBookAmountApplied - #AppliedReceivableDetailInfo.BookAmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	OUTPUT INSERTED.Amount_Amount AS Amount, INSERTED.EffectiveBalance_Amount AS Balance INTO #ReceivableDetailsInfo
	FROM ReceivableDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetails.Id = #AppliedReceivableDetailInfo.ReceivableDetailId;

	IF EXISTS( 
		SELECT * FROM #ReceivableDetailsInfo
		WHERE (Amount > 0 AND Balance < 0) 
		OR (Amount < 0 AND Balance > 0)
	)
		SET @IsOverApplicationExist = 1	

	-- Receivables
	UPDATE ReceivableDetailsWithHoldingTaxDetails
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount +#AppliedReceivableDetailInfo.PreviousAdjustedWithHoldingTax - #AppliedReceivableDetailInfo.AdjustedWithHoldingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetailsWithHoldingTaxDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableDetailsWithHoldingTaxDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId;


	-- Receivables
	SELECT 
		ReceivableId,
		SUM(AmountApplied) AmountApplied,
		SUM(PreviousAmountApplied) PreviousAmountApplied,
		SUM(AdjustedWithHoldingTax) AdjustedWithHoldingTax,
		SUM(PreviousAdjustedWithHoldingTax) PreviousAdjustedWithHoldingTax
	INTO #TempReceivableGroupedInfo
	FROM #AppliedReceivableDetailInfo
	GROUP BY ReceivableId

	UPDATE Receivables
	SET 
	    TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount + #TempReceivableGroupedInfo.PreviousAmountApplied - #TempReceivableGroupedInfo.AmountApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM Receivables
	JOIN #TempReceivableGroupedInfo ON Receivables.Id = #TempReceivableGroupedInfo.ReceivableId;	

	UPDATE ReceivableWithholdingTaxDetails
	SET
		EffectiveBalance_Amount = EffectiveBalance_Amount + #TempReceivableGroupedInfo.PreviousAdjustedWithHoldingTax - #TempReceivableGroupedInfo.AdjustedWithholdingTax,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableWithholdingTaxDetails
	JOIN #TempReceivableGroupedInfo ON ReceivableWithholdingTaxDetails.ReceivableId = #TempReceivableGroupedInfo.ReceivableId;	
	
	--Receipt Application Receivable Tax Impositions - Calculation
	IF (@IsReceiptApplication = 0)
	BEGIN
		INSERT INTO #ReceiptAppReceivableTaxDetails
		SELECT 
			ReceiptApplicationReceivableDetails.Id,
			ReceiptApplicationId,
			ReceivedDate,
			ReceivableDetailId,
			TaxApplied_Amount TaxApplied,
			PreviousTaxApplied_Amount PreviousTaxApplied,
			SUM(TaxApplied_Amount) OVER (PARTITION BY ReceivableDetailId ORDER BY ReceiptId, ReceivedDate) AS RunningTaxApplied
			,ReceiptApplicationReceivableDetails.IsReApplication
		FROM #ReceiptApplicationInfo
		JOIN ReceiptApplicationReceivableDetails ON #ReceiptApplicationInfo.ApplicationId = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		AND (ReceiptApplicationReceivableDetails.AmountApplied_Amount != ReceiptApplicationReceivableDetails.PreviousAmountApplied_Amount
		OR ReceiptApplicationReceivableDetails.TaxApplied_Amount != ReceiptApplicationReceivableDetails.PreviousTaxApplied_Amount
		OR ReceiptApplicationReceivableDetails.BookAmountApplied_Amount != PreviousBookAmountApplied_Amount)
		

		INSERT INTO #PrevReceiptAppReceivableTaxImpositions
		SELECT ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId, SUM(ReceiptApplicationReceivableTaxImpositions.AmountPosted_Amount), 0
		FROM #ReceiptApplicationInfo
		JOIN ReceiptApplicationReceivableTaxImpositions ON #ReceiptApplicationInfo.ApplicationId = ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId 
			AND ReceiptApplicationReceivableTaxImpositions.IsActive=1
			AND ReceiptApplicationReceivableTaxImpositions.AmountPosted_Amount != 0.00
		GROUP BY ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId
	END

	INSERT INTO #ReceiptAppReceivableTaxImpositions
	SELECT 
		ROW_NUMBER() OVER (ORDER BY ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) Id,
		#ReceiptAppReceivableTaxDetails.Id AS RARDId,
		#ReceiptAppReceivableTaxDetails.ReceivableDetailId,
		#ReceiptAppReceivableTaxDetails.ReceiptApplicationId,
		#ReceiptAppReceivableTaxDetails.TaxApplied,
		#ReceiptAppReceivableTaxDetails.RunningTaxApplied,
		ReceivableTaxImpositions.Id [TaxImpositionId],
		ReceivableTaxImpositions.EffectiveBalance_Amount + ISNULL(#PrevReceiptAppReceivableTaxImpositions.PrevPostedAmount, 0.00) [EffectiveTaxBalance],
		SUM(ReceivableTaxImpositions.EffectiveBalance_Amount + ISNULL(#PrevReceiptAppReceivableTaxImpositions.PrevPostedAmount, 0.00)) 
			OVER (PARTITION BY #ReceiptAppReceivableTaxDetails.ReceiptApplicationId, #ReceiptAppReceivableTaxDetails.ReceivableDetailId 
			ORDER BY ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) [RunningEffectiveBalance],
		0.00 [ImpositionTaxToApply],
		0.00 [RunningImpositionTaxApplied],
		ISNULL(#PrevReceiptAppReceivableTaxImpositions.PrevPostedAmount, 0.00) [PreviousImpositionTaxApplied],
		ReceivableTaxDetails.Id [TaxDetailId],
		ReceivableTaxes.Id [ReceivableTaxId],
		ReceivableTaxDetails.Amount_Currency Currency
	FROM #ReceiptAppReceivableTaxDetails
	JOIN ReceivableTaxDetails ON #ReceiptAppReceivableTaxDetails.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive=1
	JOIN ReceivableTaxImpositions ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId AND ReceivableTaxImpositions.IsActive=1 
	JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive=1
	LEFT JOIN #PrevReceiptAppReceivableTaxImpositions ON ReceivableTaxImpositions.Id = #PrevReceiptAppReceivableTaxImpositions.ReceivableTaxImpositionId
	WHERE (#ReceiptAppReceivableTaxDetails.TaxApplied != 0 OR #ReceiptAppReceivableTaxDetails.PreviousTaxApplied != 0)
	AND ReceivableTaxImpositions.Balance_Amount + ISNULL(#PrevReceiptAppReceivableTaxImpositions.PrevPostedAmount, 0) <> 0 
	;

	UPDATE #ReceiptAppReceivableTaxImpositions
	SET ImpositionTaxToApply = EffectiveTaxBalance,
		RunningImpositionTaxApplied = RunningEffectiveBalance,
		EffectiveTaxBalance = 0
	WHERE (RunningTaxApplied >= 0 AND RunningEffectiveBalance <= RunningTaxApplied) 
	OR (RunningTaxApplied < 0 AND RunningEffectiveBalance >= RunningTaxApplied);

	;WITH CTE_RemainingTaxAmtToApply (Id,RemainingAmountToApply) AS
	(
		SELECT 
			TaxImpositionWithBalanceToUpdate.Id,
			RemainingTaxDetailsToApply.RemainingTaxToApply
		FROM (SELECT RARDId,RunningTaxApplied - SUM(ImpositionTaxToApply) RemainingTaxToApply 
			FROM #ReceiptAppReceivableTaxImpositions 
			GROUP BY RARDId,RunningTaxApplied
			HAVING RunningTaxApplied - SUM(ImpositionTaxToApply) != 0)  

		AS RemainingTaxDetailsToApply	
		JOIN (SELECT RARDId,MIN(Id) Id 
			FROM #ReceiptAppReceivableTaxImpositions 
			WHERE EffectiveTaxBalance <> 0 
			GROUP BY RARDId) 
		AS TaxImpositionWithBalanceToUpdate ON RemainingTaxDetailsToApply.RARDId = TaxImpositionWithBalanceToUpdate.RARDId
	)
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET 
		ImpositionTaxToApply = ImpositionTaxToApply + CTE_RemainingTaxAmtToApply.RemainingAmountToApply,
		EffectiveTaxBalance = EffectiveTaxBalance - CTE_RemainingTaxAmtToApply.RemainingAmountToApply,
		RunningImpositionTaxApplied = RunningTaxApplied
	FROM #ReceiptAppReceivableTaxImpositions
	JOIN CTE_RemainingTaxAmtToApply ON #ReceiptAppReceivableTaxImpositions.Id = CTE_RemainingTaxAmtToApply.Id;
	
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET ImpositionTaxToApply = 0
	WHERE RunningTaxApplied - TaxApplied != 0
	AND RunningImpositionTaxApplied <= RunningTaxApplied - TaxApplied;

	;WITH CTE_RemainingImpositionToClear (Id,TaxToClear) AS
	(
		SELECT 
			TaxImpositionWithExtractTaxAppliedToClear.Id,
			RemainingTaxDetailsToClear.TaxToClear
		FROM (SELECT RARDId,SUM(ImpositionTaxToApply) - TaxApplied TaxToClear 
			FROM #ReceiptAppReceivableTaxImpositions 
			GROUP BY RARDId,TaxApplied
			HAVING SUM(ImpositionTaxToApply) - TaxApplied != 0)  
		AS RemainingTaxDetailsToClear
		JOIN (SELECT RARDId,MIN(Id) Id 
			FROM #ReceiptAppReceivableTaxImpositions 
			WHERE ImpositionTaxToApply <> 0 
			GROUP BY RARDId) 
		AS TaxImpositionWithExtractTaxAppliedToClear ON RemainingTaxDetailsToClear.RARDId = TaxImpositionWithExtractTaxAppliedToClear.RARDId
	)
	UPDATE #ReceiptAppReceivableTaxImpositions
	SET 
		ImpositionTaxToApply = ImpositionTaxToApply - CTE_RemainingImpositionToClear.TaxToClear
	FROM #ReceiptAppReceivableTaxImpositions
	JOIN CTE_RemainingImpositionToClear ON #ReceiptAppReceivableTaxImpositions.Id = CTE_RemainingImpositionToClear.Id;

	--ReceiptApplicationReceivableTaxImpositions

	SELECT 
		ReceiptApplicationId, 
		TaxImpositionId, 
		Currency, 
		CASE WHEN p.IsReApplication = 1 THEN ImpositionTaxToApply - p.PrevPostedAmount ELSE ImpositionTaxToApply END AS ImpositionTaxToApply,
		CAST(1 AS BIT) IsActive,
		CAST(Null AS bigint) RARTImpositionId
	INTO #TaxImpositions
	FROM #ReceiptAppReceivableTaxImpositions r
	LEFT JOIN #PrevReceiptAppReceivableTaxImpositions p ON r.TaxImpositionId = p.ReceivableTaxImpositionId
	GROUP BY ReceiptApplicationId, TaxImpositionId, Currency, IsReApplication, ImpositionTaxToApply, p.PrevPostedAmount

	UPDATE #TaxImpositions
	SET RARTImpositionId = ReceiptApplicationReceivableTaxImpositions.Id,
	    IsActive = CASE WHEN #TaxImpositions.ImpositionTaxToApply = 0 THEN 0 ELSE 1 END
	FROM #TaxImpositions
	JOIN ReceiptApplicationReceivableTaxImpositions ON #TaxImpositions.ReceiptApplicationId = ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId AND #TaxImpositions.TaxImpositionId = ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId 
	WHERE ReceiptApplicationReceivableTaxImpositions.IsActive = 1

	DELETE FROM #TaxImpositions WHERE RARTImpositionId IS NULL AND ImpositionTaxToApply = 0

	IF EXISTS(SELECT 1 FROM #TaxImpositions WHERE RARTImpositionId IS NOT NULL)
	BEGIN
		UPDATE ReceiptApplicationReceivableTaxImpositions
			SET AmountPosted_Amount = #TaxImpositions.ImpositionTaxToApply, 
				IsActive = #TaxImpositions.IsActive,
				UpdatedById = @CurrentUserId,
				UpdatedTime = @CurrentTime 
		FROM ReceiptApplicationReceivableTaxImpositions
		JOIN #TaxImpositions ON ReceiptApplicationReceivableTaxImpositions.Id = #TaxImpositions.RARTImpositionId
		WHERE RARTImpositionId IS NOT NULL

		DELETE FROM #TaxImpositions WHERE RARTImpositionId IS NOT NULL
	END

	INSERT INTO ReceiptApplicationReceivableTaxImpositions (ReceiptApplicationId,AmountPosted_Amount, AmountPosted_Currency, IsActive, ReceivableTaxImpositionId, CreatedById,CreatedTime) 
	SELECT 
		Source.ReceiptApplicationId, 
		Source.ImpositionTaxToApply, 
		Source.Currency, 
		Source.IsActive, 
		Source.TaxImpositionId, 
		@CurrentUserId, 
		@CurrentTime
	FROM #TaxImpositions Source

	--Receivable Tax Impositions

	;WITH CTE_TaxImpositionDetails(TaxImpositionId,PreviousAmountApplied, AmountToApply) AS 
	(
		SELECT 
			TaxImpositionId,
			SUM(PreviousImpositionTaxApplied) PreviousAmountApplied,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00 OR PreviousImpositionTaxApplied <> 0.00
		GROUP BY TaxImpositionId
	)
	UPDATE ReceivableTaxImpositions
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount + PreviousAmountApplied - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions
	JOIN CTE_TaxImpositionDetails ON ReceivableTaxImpositions.Id = CTE_TaxImpositionDetails.TaxImpositionId
	WHERE CTE_TaxImpositionDetails.AmountToApply <> 0.00 OR PreviousAmountApplied <> 0.00

	--Receivable Tax Details

	CREATE TABLE #ReceivableTaxDetailsInfo (Amount DECIMAL, Balance DECIMAL)

	;WITH CTE_TaxDetails(TaxDetailId,PreviousAmountApplied, AmountToApply) AS 
	(
		SELECT 
			TaxDetailId,
			SUM(PreviousImpositionTaxApplied) PreviousAmountApplied,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00 OR PreviousImpositionTaxApplied <> 0.00
		GROUP BY TaxDetailId
	)
	UPDATE ReceivableTaxDetails
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount + PreviousAmountApplied - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	OUTPUT INSERTED.Amount_Amount AS Amount, INSERTED.EffectiveBalance_Amount AS Balance INTO #ReceivableTaxDetailsInfo
	FROM ReceivableTaxDetails
	JOIN CTE_TaxDetails ON ReceivableTaxDetails.Id = CTE_TaxDetails.TaxDetailId

	IF EXISTS( 
		SELECT * FROM #ReceivableTaxDetailsInfo
		WHERE (Amount > 0 AND Balance < 0) 
		OR (Amount < 0 AND Balance > 0)
	)
		SET @IsOverApplicationExist = 1	

	--Receivable Taxes

	;WITH CTE_TaxDetails(ReceivableTaxId,PreviousAmountApplied, AmountToApply) AS 
	(
		SELECT 
			ReceivableTaxId,
			SUM(PreviousImpositionTaxApplied) PreviousAmountApplied,
			SUM(ImpositionTaxToApply) AmountToApply
		FROM #ReceiptAppReceivableTaxImpositions 
		WHERE ImpositionTaxToApply <> 0.00 OR PreviousImpositionTaxApplied <> 0.00
		GROUP BY ReceivableTaxId
	)
	UPDATE ReceivableTaxes
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount + PreviousAmountApplied - AmountToApply,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableTaxes
	JOIN CTE_TaxDetails ON ReceivableTaxes.Id = CTE_TaxDetails.ReceivableTaxId;	


	-- Invoice Updates --For WHT, Invoice Story columns need to be taken for consideration later
	UPDATE #AppliedReceivableDetailInfo
	SET ReceivableInvoiceId = ReceivableInvoices.Id
	FROM #AppliedReceivableDetailInfo
	JOIN ReceivableInvoiceDetails ON #AppliedReceivableDetailInfo.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
	JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1; 

	UPDATE ReceivableInvoiceDetails 
	SET 
		EffectiveBalance_Amount = EffectiveBalance_Amount + #AppliedReceivableDetailInfo.PreviousAmountApplied - #AppliedReceivableDetailInfo.AmountApplied,
		EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount + #AppliedReceivableDetailInfo.PreviousTaxApplied - #AppliedReceivableDetailInfo.TaxApplied,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableInvoiceDetails
	JOIN #AppliedReceivableDetailInfo ON ReceivableInvoiceDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId
		AND ReceivableInvoiceDetails.ReceivableInvoiceId = #AppliedReceivableDetailInfo.ReceivableInvoiceId 
	WHERE ReceivableInvoiceDetails.IsActive=1

	--Receivable Invoices

	;WITH CTE_InvoiceInfo(ReceivableInvoiceId, AmountApplied, PreviousAmountApplied, TaxApplied, PreviousTaxApplied) AS
	(
		SELECT
			ReceivableInvoiceId,
			SUM(AmountApplied) AmountApplied, 
			SUM(PreviousAmountApplied) PreviousAmountApplied, 
			SUM(TaxApplied) TaxApplied, 
			SUM(PreviousTaxApplied) PreviousTaxApplied
		FROM #AppliedReceivableDetailInfo
		WHERE ReceivableInvoiceId IS NOT NULL
		GROUP BY ReceivableInvoiceId
	)
	UPDATE    
		ReceivableInvoices     
	SET     
		EffectiveBalance_Amount = EffectiveBalance_Amount + PreviousAmountApplied - AmountApplied,   
		EffectiveTaxBalance_Amount = EffectiveTaxBalance_Amount + PreviousTaxApplied - TaxApplied,   
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime     
	FROM     
		ReceivableInvoices    
		JOIN CTE_InvoiceInfo AS InvoiceInfo ON InvoiceInfo.ReceivableInvoiceId = ReceivableInvoices.Id;

	--Sync Previous Amt Applied & InvoiceId in ReceiptApplication Tables
	
		UPDATE
		ReceiptApplicationReceivableDetails 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableDetails.TaxApplied_Amount,
		PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime,
		ReceivableInvoiceId = #AppliedReceivableDetailInfo.ReceivableInvoiceId,
		PrevLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
		PrevNonLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount
	FROM 
		ReceiptApplicationReceivableDetails
	JOIN #ReceiptApplicationInfo ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId
	JOIN #AppliedReceivableDetailInfo ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #AppliedReceivableDetailInfo.ReceivableDetailId;

		UPDATE
		ReceiptApplicationInvoices 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount,
		PreviousTaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationInvoices
	JOIN #ReceiptApplicationInfo ON ReceiptApplicationInvoices.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId;

	UPDATE
		ReceiptApplicationReceivableGroups 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableGroups.TaxApplied_Amount,
		PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableGroups.BookAmountApplied_Amount,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableGroups.AdjustedWithHoldingTax_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationReceivableGroups
	JOIN #ReceiptApplicationInfo ON ReceiptApplicationReceivableGroups.ReceiptApplicationId = #ReceiptApplicationInfo.ApplicationId;

    SELECT 
		RI.StatementInvoiceId, 
		Sum(RD.AmountApplied) AmountApplied, 
		SUM(RD.TaxApplied) TaxApplied ,
		SUM(RD.PreviousAmountApplied) PreviousAmountApplied, 
        SUM(RD.PreviousTaxApplied) PreviousTaxApplied
	INTO #StatementInvoicesOfReceivableInvoices
	FROM #AppliedReceivableDetailInfo RD 
	INNER JOIN ReceivableInvoiceStatementAssociations RI ON RD.ReceivableInvoiceId = RI.ReceivableInvoiceId
	INNER JOIN ReceivableInvoices SI ON SI.Id = RI.StatementInvoiceId AND SI.IsActive = 1
	GROUP BY RI.StatementInvoiceId

	IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
	BEGIN
		UPDATE RI
		SET 
		   EffectiveBalance_Amount =  EffectiveBalance_Amount + PreviousAmountApplied - SRI.AmountApplied,
		   EffectiveTaxBalance_Amount =  EffectiveTaxBalance_Amount + PreviousTaxApplied - SRI.TaxApplied,
		   UpdatedById = @CurrentUserId, 
		   UpdatedTime = @CurrentTime
		FROM ReceivableInvoices RI
		INNER JOIN #StatementInvoicesOfReceivableInvoices SRI 
			ON RI.Id = SRI.StatementInvoiceId
	END
	
	DROP TABLE #ReceiptApplicationInfo
	DROP TABLE #AppliedReceivableDetailInfo
	DROP TABLE #ReceiptAppReceivableTaxDetails
	DROP TABLE #ReceiptAppReceivableTaxImpositions
	DROP TABLE #PrevReceiptAppReceivableTaxImpositions
	DROP TABLE #StatementInvoicesOfReceivableInvoices
	DROP TABLE #TempReceivableGroupedInfo
END

GO
