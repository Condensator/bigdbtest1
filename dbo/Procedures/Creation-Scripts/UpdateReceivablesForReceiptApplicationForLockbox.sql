SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceivablesForReceiptApplicationForLockbox]
(
@ReceiptId BIGINT,
@ContractId BIGINT, 
@UpdateBalance BIT, 
@CurrentUserId BIGINT,
@ApplicationId BIGINT, 
@IsNewlyAdded BIT,
@IsReversal BIT,
@IsApplyByReceivable BIT,
@IsFromBatch BIT,
@CurrentTime DATETIMEOFFSET,
@ReceivedDate DATE
)
AS
BEGIN
--PRINT(SYSDATETIMEOFFSET())
--DECLARE @ReceiptId BIGINT =10306,
--@ContractId BIGINT = 40896, 
--@UpdateBalance BIT = 1, 
--@CurrentUserId BIGINT = 20123,
--@ApplicationId BIGINT= 10352, 
--@IsNewlyAdded BIT = 0,
--@IsReversal BIT = 0,
--@IsApplyByReceivable BIT = 0,
--@IsFromBatch BIT= 0 ,
--@CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET(),
--@ReceivedDate DATE = GETDATE()

--BEGIN TRAN T

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	CREATE TABLE #TaxImpositions
	(
		Id BIGINT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
		TaxImpositionId BIGINT NOT NULL,
		ApplicationDetailId BIGINT NOT NULL,
		TaxBalance DECIMAL(18,2) NOT NULL,
		AmountToApply DECIMAL(18,2) NOT NULL,
		TaxApplied DECIMAL(18,2) NOT NULL,
		NextApplicationDetailId BIGINT NOT NULL,
		NextTaxApplied DECIMAL(18,2) NOT NULL,
		Currency NVARCHAR(3) NOT NULL,
		IsActive BIT NOT NULL,
		IsReApplication BIT NOT NULL
	);
		
	CREATE TABLE #TaxTemp
	(
		TaxImpositionId BIGINT NOT NULL,
		ApplicationId BIGINT NOT NULL,
		AmountApplied DECIMAL(18,2) NOT NULL,
		Currency NVARCHAR(3) NOT NULL,
		IsActive BIT NOT NULL,
		IsNewlyAdded BIT NOT NULL,
	);

	CREATE TABLE #TempId
	(
		ReceiptApplicationId BIGINT NOT NULL
	);

	CREATE TABLE #TempApplicationReceivableDetails
	(
		Id BIGINT NOT NULL, 
		AmountApplied_Amount DECIMAL(18,2) NOT NULL, 
		TaxApplied_Amount DECIMAL(18,2) NOT NULL,
		BookAmountApplied_Amount DECIMAL(18,2) NOT NULL,
		LeaseComponentAmountApplied_Amount DECIMAL(18,2) NOT NULL, 
		NonLeaseComponentAmountApplied_Amount  DECIMAL(18,2) NOT NULL, 
	);

	CREATE TABLE #TempReceiptApplicationInvoices
	(
		Id BIGINT NOT NULL, 
		AmountApplied_Amount DECIMAL(18,2) NOT NULL, 
		TaxApplied_Amount DECIMAL(18,2) NOT NULL
	);

	CREATE TABLE #TempReceivableInvoiceDetails
	(
		ReceivableInvoiceId BIGINT NOT NULL,
		ReceivableDetailId BIGINT PRIMARY KEY CLUSTERED,
		Balance_Amount DECIMAL(18,2) NOT NULL, 
		EffectiveBalance_Amount DECIMAL(18,2) NOT NULL,
		TaxBalance_Amount DECIMAL(18,2) NOT NULL, 
		EffectiveTaxBalance_Amount DECIMAL(18,2) NOT NULL,
	);


	CREATE NONCLUSTERED INDEX temp_InvoiceId 
    ON #TempReceivableInvoiceDetails (ReceivableInvoiceId);
	

	CREATE NONCLUSTERED INDEX ClusteredIndex_Id 
    ON #TaxTemp (TaxImpositionId)

	UPDATE 	ReceivableDetails 
	SET Balance_Amount = Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount,
		EffectiveBookBalance_Amount =EffectiveBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
		EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
		LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
		NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetails 
	INNER JOIN ReceiptApplicationReceivableDetails 
	ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	AND ReceivableDetails.IsActive=1;	

	  DECLARE @ReceivableIds TABLE(ReceivableId BIGINT) 
	   
	  INSERT INTO @ReceivableIds(ReceivableId)  
	  SELECT 	
		  DISTINCT ReceivableDetails.ReceivableId AS ReceivableId    
	  FROM      
		ReceivableDetails    
	  INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId    
	  WHERE     
	  	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId 
		AND ReceivableDetails.IsActive=1 
	  GROUP BY ReceivableDetails.ReceivableId 
	   
  	  
	  DECLARE @ReceivableAmountTable TABLE(ReceivableId BIGINT, Balance_Amount DECIMAL(18,2), EffectiveBalance_Amount DECIMAL(18,2),EffectiveBookBalance_Amount DECIMAL(18,2))  

	  INSERT INTO @ReceivableAmountTable (ReceivableId, Balance_Amount, EffectiveBalance_Amount,EffectiveBookBalance_Amount)    
	  SELECT      
	  			ReceivableDetails.ReceivableId AS ReceivableId,
	  			SUM(ReceivableDetails.Balance_Amount) AS Balance_Amount,
	  			SUM(ReceivableDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount,
	  			SUM(ReceivableDetails.EffectiveBookBalance_Amount) AS EffectiveBookBalance_Amount
	  		FROM 
	  			ReceivableDetails
				INNER JOIN @ReceivableIds ReceivableIds ON ReceivableDetails.ReceivableId = ReceivableIds.ReceivableId  
			WHERE ReceivableDetails.IsActive=1
	  		GROUP BY ReceivableDetails.ReceivableId
	--PRINT (SYSDATETIMEOFFSET())
	UPDATE
		Receivables 
	SET 
		TotalBalance_Amount = Balance_Amount,
		TotalEffectiveBalance_Amount = EffectiveBalance_Amount,
		TotalBookBalance_Amount = EffectiveBookBalance_Amount,
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime 
	FROM 
		Receivables
		INNER JOIN @ReceivableAmountTable ON ReceivableId = Receivables.Id
		WHERE Receivables.IsDummy = 0
		AND Receivables.IsActive=1

	UPDATE
		ReceiptApplicationReceivableDetails 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationReceivableDetails.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableDetails.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationReceivableDetails.TaxApplied_Currency,
		PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
		PreviousBookAmountApplied_Currency = ReceiptApplicationReceivableDetails.BookAmountApplied_Currency,
		PrevLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
		PrevLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Currency,
		PrevNonLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount,
		PrevNonLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Currency,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationReceivableDetails
	WHERE 
		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationReceivableDetails.IsReApplication = 0;

	UPDATE
		ReceiptApplicationReceivableDetails
	SET		
		ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM
		ReceiptApplicationReceivableDetails
		JOIN #TempReceivableInvoiceDetails ON #TempReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationReceivableDetails.IsReApplication = 0


	--ReceivableInvoiceReceiptDetail
	IF (@UpdateBalance = 1 AND @IsReversal = 0)
	BEGIN
		SELECT
			@ReceiptId AS ReceiptId,
			ReceiptApplicationReceivableDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
			SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied,
			SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied,
			ReceiptApplicationReceivableDetails.AmountApplied_Currency AS Currency	
		INTO #TempReceiptApplicationReceivableDetail	
		FROM 
			ReceiptApplicationReceivableDetails
			JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
		GROUP BY ReceiptApplicationReceivableDetails.ReceivableInvoiceId,ReceiptApplicationReceivableDetails.AmountApplied_Currency

		SELECT 
				CAST(0.00 AS  Decimal(16,2)) AS AmountApplied,
				CAST(0.00 AS  Decimal(16,2)) AS TaxApplied,
				ReceivableInvoiceReceiptDetails.ReceivedDate AS ReceivedDate,
				ReceivableInvoiceReceiptDetails.AmountApplied_Currency AS Currency,
				@ReceiptId AS ReceiptId,
				ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
				CAST(0 AS BIT) AS IsNewlyAdded
		INTO #TempReceivableInvoiceReceiptDetail
		FROM ReceivableInvoiceReceiptDetails
		WHERE ReceivableInvoiceReceiptDetails.ReceiptId = @ReceiptId
				AND ReceivableInvoiceReceiptDetails.IsActive = 1

		--select count(*) from #TempReceivableInvoiceReceiptDetail

		MERGE #TempReceivableInvoiceReceiptDetail AS T
			USING #TempReceiptApplicationReceivableDetail AS S
			ON (T.ReceiptId = S.ReceiptId AND T.ReceivableInvoiceId = S.ReceivableInvoiceId) 
			WHEN MATCHED 
				THEN UPDATE
					SET T.AmountApplied = S.AmountApplied, T.TaxApplied = S.TaxApplied, T.IsNewlyAdded = 0
			WHEN NOT MATCHED BY TARGET
				THEN INSERT
					(AmountApplied, TaxApplied, Currency, ReceiptId, ReceivedDate, ReceivableInvoiceId, IsNewlyAdded) 
				VALUES
					(S.AmountApplied, S.TaxApplied, S.Currency, @ReceiptId, @ReceivedDate, S.ReceivableInvoiceId, 1);

		UPDATE 
			ReceivableInvoiceReceiptDetails
		SET
			AmountApplied_Amount = #TempReceivableInvoiceReceiptDetail.AmountApplied,
			TaxApplied_Amount = #TempReceivableInvoiceReceiptDetail.TaxApplied,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
		FROM ReceivableInvoiceReceiptDetails
		JOIN #TempReceivableInvoiceReceiptDetail ON ReceivableInvoiceReceiptDetails.ReceiptId = #TempReceivableInvoiceReceiptDetail.ReceiptId
				AND ReceivableInvoiceReceiptDetails.ReceivableInvoiceId = #TempReceivableInvoiceReceiptDetail.ReceivableInvoiceId
		WHERE #TempReceivableInvoiceReceiptDetail.IsNewlyAdded = 0
				AND ReceivableInvoiceReceiptDetails.IsActive = 1

		INSERT INTO ReceivableInvoiceReceiptDetails (ReceiptId, ReceivedDate, IsActive, ReceivableInvoiceId,
													AmountApplied_Amount, AmountApplied_Currency, TaxApplied_Amount, TaxApplied_Currency,  CreatedById, CreatedTime)
		SELECT 
				@ReceiptId AS ReceiptId,
				#TempReceivableInvoiceReceiptDetail.ReceivedDate AS ReceivedDate,
				1 AS IsActive,
				#TempReceivableInvoiceReceiptDetail.ReceivableInvoiceId AS ReceivableInvoiceId,
				#TempReceivableInvoiceReceiptDetail.AmountApplied AS AmountApplied_Amount,
				#TempReceivableInvoiceReceiptDetail.Currency AS AmountApplied_Currency,
				#TempReceivableInvoiceReceiptDetail.TaxApplied AS TaxApplied_Amount,
				#TempReceivableInvoiceReceiptDetail.Currency AS TaxApplied_Currency,
				@CurrentUserId AS CreatedById,
				@CurrentTime AS CreatedTime				     
			FROM 
				#TempReceivableInvoiceReceiptDetail 
			WHERE 
				#TempReceivableInvoiceReceiptDetail.IsNewlyAdded = 1

		PRINT 'Update Receivable Invoice Receipt Details'

		UPDATE 
			ReceivableInvoices
		SET
			LastReceivedDate = LastReceivedDateDetails.LastReceivedDate,
			UpdatedById = @CurrentUserId, 
			UpdatedTime = @CurrentTime 
		FROM ReceivableInvoices
		JOIN
		(SELECT ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
				MAX(ReceivableInvoiceReceiptDetails.ReceivedDate) AS LastReceivedDate
		 FROM ReceivableInvoiceReceiptDetails
			  JOIN #TempReceivableInvoiceReceiptDetail ON #TempReceivableInvoiceReceiptDetail.ReceivableInvoiceId = ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
		 WHERE ReceivableInvoiceReceiptDetails.IsActive = 1
				AND (ReceivableInvoiceReceiptDetails.AmountApplied_Amount != 0
					 OR ReceivableInvoiceReceiptDetails.TaxApplied_Amount != 0)
		 GROUP BY ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
		) AS LastReceivedDateDetails ON LastReceivedDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		WHERE ReceivableInvoices.IsDummy = 0
		AND ReceivableInvoices.IsActive = 1

		DROP TABLE #TempReceiptApplicationReceivableDetail
		DROP TABLE #TempReceivableInvoiceReceiptDetail
	END
	--ReceivableInvoiceReceiptDetail

	--PRINT 'Update Receivable Invoices'

	UPDATE
		ReceiptApplicationInvoices 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationInvoices.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationInvoices.TaxApplied_Currency,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationInvoices
	WHERE 
		ReceiptApplicationInvoices.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationInvoices.IsReApplication = 0;

	--PRINT 'Update Receivable Groups'

	UPDATE
		ReceiptApplicationReceivableGroups 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationReceivableGroups.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableGroups.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationReceivableGroups.TaxApplied_Currency,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationReceivableGroups
	WHERE 
		ReceiptApplicationReceivableGroups.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationReceivableGroups.IsReApplication = 0;


	IF @IsReversal = 0
	BEGIN

		INSERT INTO #TempId
		SELECT 
			ReceiptApplicationReceivableDetails.ReceiptApplicationId AS ReceiptApplicationId
		FROM 
			ReceiptApplications
		JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		JOIN 
			(SELECT 
				ReceiptApplicationReceivableDetails.ReceivableDetailId 
				FROM 
					ReceiptApplicationReceivableDetails 
				WHERE 
				ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
				AND ReceiptApplicationReceivableDetails.IsReApplication = 1) AS ReceiptReceivableDetail 
		ON ReceiptReceivableDetail.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplicationReceivableDetails.IsReApplication = 0
		GROUP BY ReceiptApplicationReceivableDetails.ReceiptApplicationId

		INSERT INTO #TempId
		SELECT 
			ReceiptApplications.Id AS ReceiptApplicationId
		FROM
			ReceiptApplications
		LEFT JOIN ReceiptApplicationDetails ON ReceiptApplicationDetails.ReceiptApplicationId = ReceiptApplications.Id
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId
			AND ReceiptApplicationDetails.Id IS NOT NULL

		INSERT INTO #TaxTemp
		SELECT
			ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId AS TaxImpositionId,
			ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId AS ApplicationId,
			ReceiptApplicationReceivableTaxImpositions.AmountPosted_Amount AS AmountApplied,
			ReceiptApplicationReceivableTaxImpositions.AmountPosted_Currency AS Currency,
			0 AS IsActive,
			0 AS IsNewlyAdded
		FROM 
			ReceiptApplicationReceivableTaxImpositions
			JOIN #TempId ON #TempId.ReceiptApplicationId = ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId
		WHERE 
			ReceiptApplicationReceivableTaxImpositions.IsActive = 1;
	END

	SELECT 
		ReceivableTaxDetails.ReceivableDetailId, SUM(#TaxTemp.AmountApplied) AS TaxApplied
	INTO #TempTaxApplied
	FROM 
		#TaxTemp
		JOIN ReceivableTaxImpositions ON #TaxTemp.TaxImpositionId = ReceivableTaxImpositions.Id
		JOIN ReceivableTaxDetails ON ReceivableTaxImpositions.ReceivableTaxDetailId = ReceivableTaxDetails.Id AND ReceivableTaxDetails.IsActive=1
	WHERE ReceivableTaxImpositions.IsActive=1	
	GROUP BY ReceivableTaxDetails.ReceivableDetailId;

	--PRINT('CTE ---'); -- Converted CTE to temp table
SELECT
			ROW_NUMBER() OVER (ORDER BY ReceiptApplicationReceivableDetails.Id,ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) AS RowNumber,
			ReceivableTaxImpositions.Id AS TaxImpositionId,
			ReceiptApplicationReceivableDetails.Id AS ApplicationDetailId, 
			ReceivableTaxImpositions.EffectiveBalance_Amount + ISNULL(#TaxTemp.AmountApplied,0.0) AS TaxBalance,
			0.0 AS AmountToApply,
			CASE WHEN (ReceiptApplicationReceivableDetails.IsReApplication = 1 AND @IsReversal = 0) THEN (ReceiptApplicationReceivableDetails.TaxApplied_Amount + ISNULL(#TempTaxApplied.TaxApplied, 0.0)) ELSE ReceiptApplicationReceivableDetails.TaxApplied_Amount END AS TaxApplied,
			ReceiptApplicationReceivableDetails.TaxApplied_Currency AS Currency,
			ReceiptApplicationReceivableDetails.IsActive AS IsActive,
			ReceiptApplicationReceivableDetails.IsReApplication AS IsReApplication 
		INTO #OrderedImposition
		FROM 
			ReceiptApplicationReceivableDetails
		INNER JOIN ReceivableTaxDetails
			ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND
			   ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		INNER JOIN ReceivableTaxImpositions
			ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId
		LEFT JOIN #TaxTemp
			ON ReceivableTaxImpositions.Id = #TaxTemp.TaxImpositionId
		LEFT JOIN #TempTaxApplied
			ON #TempTaxApplied.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId
		WHERE 
		 ReceivableTaxDetails.IsActive = 1
		AND ReceivableTaxImpositions.IsActive = 1;

	PRINT 'Tax Impostion count'
	--select * from #OrderedImposition

	INSERT INTO #TaxImpositions(TaxImpositionId,ApplicationDetailId,TaxBalance,AmountToApply,TaxApplied,NextApplicationDetailId,NextTaxApplied,Currency,IsActive,IsReApplication)
	SELECT 
		#OrderedImposition.TaxImpositionId TaxImpositionId,
		#OrderedImposition.ApplicationDetailId ApplicationDetailId,
		#OrderedImposition.TaxBalance TaxBalance,
		#OrderedImposition.AmountToApply AmountToApply,
		#OrderedImposition.TaxApplied TaxApplied,
		ISNULL(T.ApplicationDetailId,#OrderedImposition.ApplicationDetailId) NextApplicationDetailId,
		ISNULL(T.TaxApplied,#OrderedImposition.TaxApplied) NextTaxApplied,
		ISNULL(T.Currency,#OrderedImposition.Currency) Currency,
		ISNULL(#OrderedImposition.IsActive,0) IsActive,
		#OrderedImposition.IsReApplication IsReApplication
	FROM 
		#OrderedImposition
	LEFT JOIN #OrderedImposition T
		ON #OrderedImposition.RowNumber = T.RowNumber - 1
	ORDER BY #OrderedImposition.RowNumber;

	--PRINT('CTE --- Complete');


	DECLARE @Balance DECIMAL(16,2) = (SELECT TOP(1) TaxApplied FROM #TaxImpositions)

	DECLARE @Amount DECIMAL(16,2) = (SELECT TOP(1) TaxApplied FROM #TaxImpositions)



	UPDATE 
		#TaxImpositions SET  AmountToApply = CASE WHEN @Amount = 0 THEN 0
												WHEN @Amount < 0 AND TaxBalance <= 0 THEN TaxBalance
												WHEN @Amount < TaxBalance THEN @Amount 
												WHEN @Amount >= TaxBalance THEN TaxBalance
												ELSE 0 END,
								@Amount =  @Balance, 
								@Balance = CASE WHEN ApplicationDetailId <> NextApplicationDetailId THEN NextTaxApplied
											WHEN @Balance = 0 THEN 0
											WHEN @Balance < 0 AND TaxBalance < 0 THEN @Balance
											WHEN @Balance < TaxBalance THEN 0
											WHEN @Balance >= TaxBalance THEN @Balance - TaxBalance
											ELSE 0 END;

	UPDATE 
		ReceivableTaxImpositions SET Balance_Amount = CASE WHEN @UpdateBalance = 1 THEN CASE WHEN @IsReversal = 1 
															THEN (Balance_Amount + ISNULL(AmountApplied,0.0))
															ELSE CASE WHEN #TaxImpositions.IsReApplication = 1
															THEN (Balance_Amount + ISNULL(AmountApplied,0.0)) - #TaxImpositions.AmountToApply
															ELSE Balance_Amount - #TaxImpositions.AmountToApply END END
															ELSE Balance_Amount END,
	EffectiveBalance_Amount = (EffectiveBalance_Amount + ISNULL(AmountApplied,0.0)) - #TaxImpositions.AmountToApply,
	UpdatedById = @CurrentUserId,
	UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions 
	INNER JOIN #TaxImpositions 
		ON ReceivableTaxImpositions.Id = #TaxImpositions.TaxImpositionId
	LEFT JOIN #TaxTemp
		ON #TaxTemp.TaxImpositionId = ReceivableTaxImpositions.Id
	WHERE ReceivableTaxImpositions.IsActive=1;

	--PRINT 'Update Tax Impositions'

	UPDATE
		ReceivableTaxDetails 
	SET 
		Balance_Amount = TaxDetails.Balance,
		EffectiveBalance_Amount = TaxDetails.EffectiveBalance,
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime 
	FROM ReceivableTaxDetails
	INNER JOIN
		(SELECT 
			ReceivableTaxImpositions.ReceivableTaxDetailId AS ReceivableTaxDetailId,
			SUM(ReceivableTaxImpositions.Balance_Amount) AS Balance,
			SUM(ReceivableTaxImpositions.EffectiveBalance_Amount) AS EffectiveBalance
		FROM ReceivableTaxImpositions
			INNER JOIN ReceivableTaxDetails
				ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId
			INNER JOIN ReceiptApplicationReceivableDetails 
				ON ReceivableTaxDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId  
		WHERE ReceivableTaxImpositions.IsActive = 1
		    AND ReceivableTaxDetails.IsActive=1
			AND ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		GROUP BY ReceivableTaxImpositions.ReceivableTaxDetailId) AS TaxDetails
	ON TaxDetails.ReceivableTaxDetailId = ReceivableTaxDetails.Id


		--PRINT 'Update Tax Impositions -- 1'

	  DECLARE @ReceivableTaxIds TABLE(ReceivableTaxId BIGINT)  
	  INSERT INTO @ReceivableTaxIds(ReceivableTaxId)  
	  SELECT 
		ReceivableTaxDetails.ReceivableTaxId AS ReceivableTaxId
		FROM  
		ReceivableTaxDetails
		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableTaxDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
		INNER JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id
		WHERE 
		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		AND ReceivableTaxDetails.IsActive=1
		AND ReceivableTaxes.IsActive=1
		GROUP BY ReceivableTaxDetails.ReceivableTaxId
  	  

	  --PRINT 'Update Tax Impositions --- 3'
	  DECLARE @CTEReceivableTaxAmount table(ReceivableTaxId bigint, Balance_Amount decimal(18,2), EffectiveBalance_Amount decimal(18,2))  
	  INSERT INTO @CTEReceivableTaxAmount (ReceivableTaxId, Balance_Amount, EffectiveBalance_Amount)    
	  SELECT 	
			ReceivableTaxDetails.ReceivableTaxId AS ReceivableTaxId,
			SUM(ReceivableTaxDetails.Balance_Amount) AS Balance_Amount,
			SUM(ReceivableTaxDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount
	  FROM 
			ReceivableTaxDetails
	   Inner join @ReceivableTaxIds ReceivableTaxIds on  
	  ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxIds.ReceivableTaxId 
	  WHERE ReceivableTaxDetails.IsActive=1
	  GROUP BY ReceivableTaxDetails.ReceivableTaxId

	--PRINT 'Update Receivable TAx Details'

	UPDATE
		ReceivableTaxes 
	SET 
		Balance_Amount = Taxes.Balance_Amount,
		EffectiveBalance_Amount = Taxes.EffectiveBalance_Amount,
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime 
	FROM ReceivableTaxes
	INNER JOIN
		@CTEReceivableTaxAmount AS Taxes
	ON Taxes.ReceivableTaxId = ReceivableTaxes.Id
 

	--PRINT 'Update Receivable Taxes'

	IF @IsNewlyAdded = 1
	BEGIN		    
		INSERT INTO ReceiptApplicationReceivableTaxImpositions
		(AmountPosted_Amount, 
		AmountPosted_Currency, 
		ReceivableTaxImpositionId, 
		ReceiptApplicationId, 
		CreatedById, 
		CreatedTime, 
		IsActive) 
		SELECT #TaxImpositions.AmountToApply AS AmountPosted_Amount,
				#TaxImpositions.Currency AS AmountPosted_Currency, 
				#TaxImpositions.TaxImpositionId AS ReceivableTaxImpositionId, 
				@ApplicationId AS ReceiptApplicationId,
				@CurrentUserId AS CreatedById,
				@CurrentTime AS CreatedTime, 
				1 AS IsActive 
		FROM 
			#TaxImpositions
		WHERE  
			#TaxImpositions.AmountToApply <> 0
	END
	ELSE IF @IsReversal = 0
		BEGIN 
			MERGE #TaxTemp AS T
			USING #TaxImpositions AS S
			ON (T.TaxImpositionId = S.TaxImpositionId) 
			WHEN MATCHED 
				THEN UPDATE
					SET T.AmountApplied = S.AmountToApply, T.IsActive = CASE WHEN S.AmountToApply <> 0 THEN 1 ELSE 0 END, T.IsNewlyAdded = 0
			WHEN NOT MATCHED BY TARGET AND S.AmountToApply <> 0
				THEN INSERT
					(AmountApplied, Currency, IsActive, TaxImpositionId, ApplicationId, IsNewlyAdded) 
				VALUES
					(S.AmountToApply, S.Currency, S.IsActive, S.TaxImpositionId, @ApplicationId, 1);

			UPDATE 
				ReceiptApplicationReceivableTaxImpositions 
			SET 
				AmountPosted_Amount = #TaxTemp.AmountApplied, 
				IsActive = #TaxTemp.IsActive, 
				UpdatedById = @CurrentUserId, 
				UpdatedTime = @CurrentTime
			FROM 
				ReceiptApplicationReceivableTaxImpositions
				JOIN #TaxTemp ON ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId = #TaxTemp.TaxImpositionId
				AND ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId = @ApplicationId
			WHERE 
				#TaxTemp.IsNewlyAdded = 0
				AND ReceiptApplicationReceivableTaxImpositions.IsActive = 1

			INSERT INTO ReceiptApplicationReceivableTaxImpositions
			(AmountPosted_Amount, 
			AmountPosted_Currency, 
			ReceivableTaxImpositionId, 
			ReceiptApplicationId, 
			CreatedById, 
			CreatedTime, 
			IsActive)
			SELECT 
				#TaxTemp.AmountApplied AS AmountPosted_Amount,
				#TaxTemp.Currency AS AmountPosted_Currency,					    
				#TaxTemp.TaxImpositionId AS ReceivableTaxImpositionId, 
			    @ApplicationId AS ReceiptApplicationId,
				@CurrentUserId AS CreatedById,
				@CurrentTime AS CreatedTime,
				1 AS IsActive					     
			FROM 
				#TaxTemp 
			WHERE 
				#TaxTemp.IsNewlyAdded = 1
		END

		--PRINT 'UPDATE Receivable Invoice Details'	
		
		;WITH CTE_TaxDetails(ReceivableInvoiceId, ReceivableDetailId, TaxBalance_Amount, EffectiveTaxBalance_Amount) AS
		(
			SELECT 
				ReceivableInvoices.Id,
				ReceiptApplicationReceivableDetails.ReceivableDetailId,
				SUM(ReceivableTaxDetails.Balance_Amount) TaxBalance_Amount,
				SUM(ReceivableTaxDetails.EffectiveBalance_Amount) EffectiveTaxBalance_Amount
			FROM ReceiptApplicationReceivableDetails
			JOIN ReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
			JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsDummy = 0 AND ReceivableInvoices.IsActive=1
			JOIN ReceivableTaxDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive=1
			JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive=1
			WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
			GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId,ReceivableInvoices.Id
		)
		INSERT INTO #TempReceivableInvoiceDetails (ReceivableDetailId, ReceivableInvoiceId, Balance_Amount, EffectiveBalance_Amount,TaxBalance_Amount, EffectiveTaxBalance_Amount)
		SELECT 
			ReceivableDetails.Id,
			ReceivableInvoices.Id,
			ReceivableDetails.Balance_Amount,
			ReceivableDetails.EffectiveBalance_Amount,
			ISNULL(TaxDetail.TaxBalance_Amount,0.00) TaxBalance_Amount,
			ISNULL(TaxDetail.EffectiveTaxBalance_Amount,0.00) EffectiveTaxBalance_Amount
		FROM ReceiptApplicationReceivableDetails
		JOIN ReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
		JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsDummy = 0 AND ReceivableInvoices.IsActive=1
		JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive=1
		JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive=1
		LEFT JOIN CTE_TaxDetails AS TaxDetail ON ReceivableDetails.Id = TaxDetail.ReceivableDetailId
		WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId;
				
		SELECT DISTINCT ReceivableInvoiceId INTO #InvoiceIds 
		FROM #TempReceivableInvoiceDetails			 

		IF(@UpdateBalance = 1) 
		BEGIN 
		--Update ReceivableInvoiceDetails
			UPDATE ReceivableInvoiceDetails 
			SET Balance_Amount = TempReceivableInvoiceDetail.Balance_Amount,
				EffectiveBalance_Amount = TempReceivableInvoiceDetail.EffectiveBalance_Amount,
				TaxBalance_Amount = TempReceivableInvoiceDetail.TaxBalance_Amount,
				EffectiveTaxBalance_Amount = TempReceivableInvoiceDetail.EffectiveTaxBalance_Amount,
				UpdatedById = @CurrentUserId,
				UpdatedTime = @CurrentTime
			FROM #TempReceivableInvoiceDetails TempReceivableInvoiceDetail
			JOIN ReceivableInvoiceDetails ON TempReceivableInvoiceDetail.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId
				AND TempReceivableInvoiceDetail.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId 
				AND ReceivableInvoiceDetails.IsActive = 1;			

		--Update ReceivableInvoices
			;WITH CTE_InvoiceDetails(ReceivableInvoiceId, Balance_Amount, EffectiveBalance_Amount, 
				TaxBalance_Amount, EffectiveTaxBalance_Amount) AS
			(			
				SELECT
					InvoiceId.ReceivableInvoiceId,
					SUM(ReceivableInvoiceDetails.Balance_Amount) Balance_Amount, 
					SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) EffectiveBalance_Amount,
					SUM(ReceivableInvoiceDetails.TaxBalance_Amount) TaxBalance_Amount, 
					SUM(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) EffectiveTaxBalance_Amount
				FROM #InvoiceIds AS InvoiceId				
				JOIN ReceivableInvoiceDetails ON InvoiceId.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId 
					AND ReceivableInvoiceDetails.IsActive = 1
				GROUP BY InvoiceId.ReceivableInvoiceId				
			)
			UPDATE    
			   ReceivableInvoices     
			SET     
			   Balance_Amount = InvoiceDetails.Balance_Amount,    
			   EffectiveBalance_Amount = InvoiceDetails.EffectiveBalance_Amount,    
			   TaxBalance_Amount = ISNULL(InvoiceDetails.TaxBalance_Amount, 0.00),
			   EffectiveTaxBalance_Amount = ISNULL(InvoiceDetails.EffectiveTaxBalance_Amount, 0.00),
			   UpdatedById = @CurrentUserId, 
			   UpdatedTime = @CurrentTime     
			FROM     
			   ReceivableInvoices    
			 JOIN  CTE_InvoiceDetails AS InvoiceDetails ON InvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		END 
		ELSE
		BEGIN
			UPDATE ReceivableInvoiceDetails 
			SET	EffectiveBalance_Amount = TempReceivableInvoiceDetail.EffectiveBalance_Amount,				
				EffectiveTaxBalance_Amount = TempReceivableInvoiceDetail.EffectiveTaxBalance_Amount,
				UpdatedById = @CurrentUserId,
				UpdatedTime = @CurrentTime
			FROM #TempReceivableInvoiceDetails TempReceivableInvoiceDetail
			JOIN ReceivableInvoiceDetails ON TempReceivableInvoiceDetail.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId
				AND TempReceivableInvoiceDetail.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId;			

		--Update ReceivableInvoices
			;WITH CTE_InvoiceDetails(ReceivableInvoiceId, EffectiveBalance_Amount, EffectiveTaxBalance_Amount) AS
			(			
				SELECT
					InvoiceId.ReceivableInvoiceId,
					SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) EffectiveBalance_Amount,
					SUM(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) EffectiveTaxBalance_Amount
				FROM #InvoiceIds AS InvoiceId				
				JOIN ReceivableInvoiceDetails ON InvoiceId.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId 
					AND ReceivableInvoiceDetails.IsActive = 1
				GROUP BY InvoiceId.ReceivableInvoiceId				
			)
			UPDATE    
			   ReceivableInvoices     
			SET       
			   EffectiveBalance_Amount = InvoiceDetails.EffectiveBalance_Amount,    
			   EffectiveTaxBalance_Amount = ISNULL(InvoiceDetails.EffectiveTaxBalance_Amount, 0.00),
			   UpdatedById = @CurrentUserId, 
			   UpdatedTime = @CurrentTime     
			FROM     
			   ReceivableInvoices    
			 JOIN  CTE_InvoiceDetails AS InvoiceDetails ON InvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		END 

--PRINT(SYSDATETIMEOFFSET())

	DROP TABLE #TaxImpositions
	DROP TABLE #TaxTemp
	DROP TABLE #TempId
	DROP TABLE #TempTaxApplied
	DROP TABLE #TempApplicationReceivableDetails
	DROP TABLE #TempReceiptApplicationInvoices
	DROP TABLE #TempReceivableInvoiceDetails;
	DROP TABLE #OrderedImposition;
	DROP TABLE #InvoiceIds;

--ROLLBACK TRAN T
END

GO
