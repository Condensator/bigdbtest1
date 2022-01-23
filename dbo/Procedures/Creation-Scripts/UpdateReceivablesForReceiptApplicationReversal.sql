SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceivablesForReceiptApplicationReversal]
(
@ReceiptId BIGINT,
@ContractId BIGINT,
@CurrentUserId BIGINT,
@ApplicationId BIGINT,
@IsApplyByReceivable BIT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
--PRINT(SYSDATETIMEOFFSET())
--DECLARE @ReceiptId BIGINT =10306,
--@ContractId BIGINT = 40896,
--@CurrentUserId BIGINT = 20123,
--@ApplicationId BIGINT= 10352,
--@IsApplyByReceivable BIT = 0,
--@CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET(),
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
		AdjustedWithholdingTax_Amount DECIMAL(18,2) NOT NULL,
		LeaseComponentAmountApplied_Amount DECIMAL(18,2) NOT NULL, 
		NonLeaseComponentAmountApplied_Amount  DECIMAL(18,2) NOT NULL, 
	);

	CREATE TABLE #TempReceiptApplicationInvoices
	(
		Id BIGINT NOT NULL, 
		AmountApplied_Amount DECIMAL(18,2) NOT NULL, 
		TaxApplied_Amount DECIMAL(18,2) NOT NULL,
		AdjustedWithHoldingTax_Amount DECIMAL(18,2) NOT NULL
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

	DECLARE @AnyInActiveApplication BIT = 0; 

		INSERT INTO #TempApplicationReceivableDetails
		SELECT 
				ReceiptApplicationReceivableDetails.Id, 
				ReceiptApplicationReceivableDetails.AmountApplied_Amount, 
				ReceiptApplicationReceivableDetails.TaxApplied_Amount,
				ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
				ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount,
				ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
			    ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount
		FROM 
			ReceiptApplicationReceivableDetails
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
		ReceiptApplications.ReceiptId = @ReceiptId
		AND ReceiptApplications.Id = @ApplicationId;

		INSERT INTO #TempReceiptApplicationInvoices
		SELECT
				ReceiptApplicationInvoices.Id, 
				ReceiptApplicationInvoices.AmountApplied_Amount, 
				ReceiptApplicationInvoices.TaxApplied_Amount,
				ReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount
		FROM 
			ReceiptApplicationInvoices
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationInvoices.ReceiptApplicationId
		WHERE 
		ReceiptApplications.ReceiptId = @ReceiptId
		AND ReceiptApplications.Id = @ApplicationId;

		UPDATE
			ReceiptApplicationReceivableDetails 
		SET 
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0, BookAmountApplied_Amount = 0.0, AdjustedWithholdingTax_Amount = 0.0, UpfrontTaxSundryId = NULL
			,LeaseComponentAmountApplied_Amount = 0.0 , NonLeaseComponentAmountApplied_Amount = 0.0, ReceivedTowardsInterest_Amount = 0.00
		FROM 
			ReceiptApplicationReceivableDetails
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId;

		UPDATE
			ReceiptApplicationInvoices 
		SET 
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0, AdjustedWithHoldingTax_Amount = 0.0
		FROM 
			ReceiptApplicationInvoices
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationInvoices.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId;

		UPDATE
			ReceivableInvoiceReceiptDetails
		SET
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0, IsActive = 0, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime 
		WHERE ReceiptId = @ReceiptId;

		SELECT ReceivableInvoiceId
		INTO #TempReceivableInvoice
		FROM 
			ReceiptApplicationReceivableDetails
			JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL

		UPDATE 
			ReceivableInvoices
		SET
			LastReceivedDate = NULL, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime 
		FROM ReceivableInvoices
			JOIN #TempReceivableInvoice ON #TempReceivableInvoice.ReceivableInvoiceId = ReceivableInvoices.Id 
		WHERE ReceivableInvoices.IsDummy = 0 
		AND ReceivableInvoices.IsActive = 1

		UPDATE 
			ReceivableInvoices
		SET
			LastReceivedDate = LastReceivedDateDetails.LastReceivedDate, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime 
		FROM ReceivableInvoices
		JOIN
		(SELECT ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
				MAX(ReceivableInvoiceReceiptDetails.ReceivedDate) AS LastReceivedDate
		 FROM ReceivableInvoiceReceiptDetails
			  JOIN #TempReceivableInvoice ON #TempReceivableInvoice.ReceivableInvoiceId = ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
		 WHERE ReceivableInvoiceReceiptDetails.IsActive = 1
				AND (ReceivableInvoiceReceiptDetails.AmountApplied_Amount != 0
					 OR ReceivableInvoiceReceiptDetails.TaxApplied_Amount != 0)
		 GROUP BY ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
		) AS LastReceivedDateDetails ON LastReceivedDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
		WHERE ReceivableInvoices.IsDummy = 0
		AND ReceivableInvoices.IsActive = 1

		DROP TABLE #TempReceivableInvoice

	UPDATE 
			ReceivableDetails 
	SET 
			Balance_Amount = Balance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),								 
			EffectiveBookBalance_Amount =  EffectiveBookBalance_Amount - (ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - ISNULL(PreviousBookAmountApplied_Amount, 0.0)),											
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
			LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - (ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount - ISNULL(PrevLeaseComponentAmountApplied_Amount, 0.0)),
			NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - (ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount - ISNULL(PrevNonLeaseComponentAmountApplied_Amount, 0.0)),
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
	FROM 
	ReceivableDetails 
	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceiptApplicationReceivableDetails.IsReApplication = 1			
	AND ReceivableDetails.IsActive=1	

	UPDATE 
			ReceivableDetailsWithholdingTaxDetails
	SET 
			Balance_Amount = Balance_Amount - (ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount - ISNULL(PreviousAdjustedWithHoldingTax_Amount, 0.0)),								 
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount - ISNULL(PreviousAdjustedWithHoldingTax_Amount, 0.0)),
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
	FROM 
	ReceivableDetailsWithholdingTaxDetails  
	INNER JOIN ReceiptApplicationReceivableDetails 
	ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId 
		AND ReceivableDetailsWithholdingTaxDetails.IsActive=1
	WHERE 
	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceiptApplicationReceivableDetails.IsReApplication = 1			
	
	UPDATE 	
			ReceivableDetails 
	SET 
			Balance_Amount = Balance_Amount + ISNULL(PreviousAmountApplied_Amount, 0.0),									
			EffectiveBookBalance_Amount = EffectiveBookBalance_Amount + ISNULL(PreviousBookAmountApplied_Amount, 0.0),								         		
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
			LeaseComponentBalance_Amount = LeaseComponentBalance_Amount +  ISNULL(PrevLeaseComponentAmountApplied_Amount, 0.0),	
			NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount + ISNULL(PrevNonLeaseComponentAmountApplied_Amount, 0.0),
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
	FROM ReceivableDetails 
	INNER JOIN ReceiptApplicationReceivableDetails 
	ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	AND ReceivableDetails.IsActive=1;
	
	UPDATE 	
			ReceivableDetailsWithholdingTaxDetails 
	SET 
			Balance_Amount = Balance_Amount + ISNULL(PreviousAdjustedWithHoldingTax_Amount, 0.0),									
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount - ISNULL(PreviousAdjustedWithHoldingTax_Amount, 0.0)),
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
	FROM 
	ReceivableDetailsWithholdingTaxDetails  
	INNER JOIN ReceiptApplicationReceivableDetails 
	ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId 
		AND ReceivableDetailsWithholdingTaxDetails.IsActive=1
	WHERE 
	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceiptApplicationReceivableDetails.IsReApplication = 0

	--PRINT 'Update Recv Details'

	  DECLARE @ReceivableIds TABLE(ReceivableId BIGINT) 
	   
	  INSERT INTO @ReceivableIds(ReceivableId)  
	  SELECT 	
		   ReceivableDetails.ReceivableId AS ReceivableId    
	  FROM      
		ReceivableDetails    
	  INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId    
	   WHERE     
	  	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId  
		AND ReceivableDetails.IsActive=1 
	  GROUP BY ReceivableDetails.ReceivableId 
  	  
  	  
	  DECLARE @ReceivableAmountTable TABLE(ReceivableId BIGINT, Balance_Amount DECIMAL(18,2), EffectiveBalance_Amount DECIMAL(18,2),EffectiveBookBalance_Amount DECIMAL(18,2))
	  DECLARE @ReceivableWithHoldingAmountTable TABLE(ReceivableWithholdingTaxDetailId BIGINT, Balance_Amount DECIMAL(18,2), EffectiveBalance_Amount DECIMAL(18,2))  

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

	  INSERT INTO @ReceivableWithHoldingAmountTable (ReceivableWithholdingTaxDetailId, Balance_Amount, EffectiveBalance_Amount)    
			SELECT      
	  			ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId AS ReceivableWithholdingTaxDetailId,
	  			SUM(ReceivableDetailsWithholdingTaxDetails.Balance_Amount) AS Balance_Amount,
	  			SUM(ReceivableDetailsWithholdingTaxDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount
	  		FROM 
	  			ReceivableDetailsWithholdingTaxDetails
				INNER JOIN ReceivableWithholdingTaxDetails ON ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId = ReceivableWithholdingTaxDetails.Id 
					AND ReceivableWithholdingTaxDetails.IsActive=1
				INNER JOIN @ReceivableIds ReceivableIds ON ReceivableWithholdingTaxDetails.ReceivableId = ReceivableIds.ReceivableId  
	  		GROUP BY ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId

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
		ReceivableWithholdingTaxDetails 
	SET 
		Balance_Amount = WHTTable.Balance_Amount,
		EffectiveBalance_Amount = WHTTable.EffectiveBalance_Amount,
		UpdatedById = @CurrentUserId, 
		UpdatedTime = @CurrentTime 
	FROM 
		ReceivableWithholdingTaxDetails
		INNER JOIN @ReceivableWithHoldingAmountTable WHTTable ON ReceivableWithholdingTaxDetails.Id = WHTTable.ReceivableWithholdingTaxDetailId
		AND ReceivableWithholdingTaxDetails.IsActive=1

	--PRINT 'Update Receivables'

	--		UPDATE ReceivableInvoiceDetails 
	--SET 
	--			Balance_Amount =CASE WHEN OriginalAmount_Amount >=0
	--							THEN CASE WHEN ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount > OriginalAmount_Amount 
	--							THEN OriginalAmount_Amount
	--							ELSE CASE WHEN  ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount <=0
	--							THEN 0
	--							ELSE ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--							END END
	--							ELSE CASE WHEN  ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount < OriginalAmount_Amount
	--							THEN OriginalAmount_Amount
	--							ELSE CASE WHEN ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount > =OriginalAmount_Amount THEN 0
	--							ELSE ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--							END END	END,
	--	EffectiveBalance_Amount =CASE WHEN OriginalAmount_Amount >=0
	--							THEN CASE WHEN  ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount > OriginalAmount_Amount 
	--							THEN OriginalAmount_Amount
	--							ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount <=0
	--							THEN 0
	--							ELSE  ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--							END END
	--							ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount < OriginalAmount_Amount
	--							THEN OriginalAmount_Amount
	--							ELSE CASE WHEN  ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount > =OriginalAmount_Amount THEN 0
	--							ELSE  ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--							END END	END,
	--			TaxBalance_Amount =CASE WHEN OriginalTaxAmount_Amount >=0
	--								THEN CASE WHEN   ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount > OriginalTaxAmount_Amount 
	--								THEN OriginalTaxAmount_Amount
	--								ELSE CASE WHEN    ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount <=0
	--								THEN 0
	--								ELSE   ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--								END END
	--								ELSE CASE WHEN    ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount < OriginalTaxAmount_Amount
	--								THEN OriginalTaxAmount_Amount
	--								ELSE CASE WHEN   ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount > =OriginalTaxAmount_Amount THEN 0
	--								ELSE   ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--								END END	END,							
	--	EffectiveTaxBalance_Amount = CASE WHEN OriginalTaxAmount_Amount >=0
	--									THEN CASE WHEN   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount > OriginalTaxAmount_Amount 
	--									THEN OriginalTaxAmount_Amount
	--									ELSE CASE WHEN    ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount <=0
	--									THEN 0
	--									ELSE   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--									END END
	--									ELSE CASE WHEN    ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount < OriginalTaxAmount_Amount
	--									THEN OriginalTaxAmount_Amount
	--									ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount > =OriginalTaxAmount_Amount THEN 0
	--									ELSE   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--									END END	END,
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--FROM ReceivableInvoiceDetails 
	--INNER JOIN ReceiptApplicationReceivableDetails 
	--	ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--INNER JOIN ReceivableInvoices
	--	ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 1
	--	AND ReceivableInvoices.IsDummy = 0
	--	AND ReceivableInvoices.IsActive = 1
	--	AND ReceivableInvoiceDetails.IsActive = 1

	--INSERT INTO #TempReceivableInvoiceDetails
	--	SELECT  
	--	ReceiptApplicationReceivableDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
	--		ReceivableInvoiceDetails.ReceivableDetailId AS ReceivableDetailId,
	--	ReceiptApplicationReceivableDetails.AmountApplied_Amount AS AmountApplied_Amount,
	--	ReceiptApplicationReceivableDetails.TaxApplied_Amount AS TaxApplied_Amount,
	--	ReceiptApplicationReceivableDetails.AmountApplied_Currency AS Currency
	--FROM 
	--	ReceivableInvoiceDetails 
	--	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--	INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--	AND ReceivableInvoices.IsDummy = 0
	--	AND ReceivableInvoices.IsActive = 1
	--	AND ReceivableInvoiceDetails.IsActive = 1
	--	AND ReceiptApplicationReceivableDetails.IsActive=1
	--	AND (ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL 
	--	OR ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId) 
		

	--UPDATE ReceivableInvoiceDetails
	--		SET Balance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0
	--								THEN CASE WHEN OriginalAmount_Amount >=0
	--								THEN CASE WHEN   ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0) > OriginalAmount_Amount 
	--								THEN OriginalAmount_Amount
	--								ELSE CASE WHEN    ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0) <=0
	--								THEN 0
	--								ELSE   ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--								END END
	--								ELSE CASE WHEN    ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0) < OriginalAmount_Amount
	--								THEN OriginalAmount_Amount
	--								ELSE CASE WHEN   ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0) > =OriginalAmount_Amount 
	--								THEN ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--								ELSE  0
	--								END END	END
	--								ELSE ReceivableInvoiceDetails.Balance_Amount
	--								 END,								
	--		EffectiveBalance_Amount =CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0
	--										THEN CASE WHEN OriginalAmount_Amount >=0
	--									THEN CASE WHEN  ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0) > OriginalAmount_Amount 
	--									THEN OriginalAmount_Amount
	--									ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0) <=0
	--									THEN 0
	--									ELSE  ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--									END END
	--									ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0) < OriginalAmount_Amount
	--									THEN OriginalAmount_Amount
	--									ELSE CASE WHEN  ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0) > =OriginalAmount_Amount 
	--									THEN ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--									ELSE 0 
	--									END END	END
	--										ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount 
	--									END,									
	--		TaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0
	--									THEN CASE WHEN OriginalTaxAmount_Amount >=0
	--									THEN CASE WHEN  ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) > OriginalTaxAmount_Amount 
	--									THEN OriginalTaxAmount_Amount
	--									ELSE CASE WHEN   ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) <=0
	--									THEN 0
	--									ELSE  ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--									END END
	--									ELSE CASE WHEN   ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) < OriginalTaxAmount_Amount
	--									THEN OriginalTaxAmount_Amount
	--									ELSE CASE WHEN  ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) > =OriginalTaxAmount_Amount 
	--									THEN ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--									ELSE  0
	--									END END	END
	--									ELSE ReceivableInvoiceDetails.TaxBalance_Amount
	--								END,
	--		EffectiveTaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0
	--											THEN CASE WHEN OriginalTaxAmount_Amount >=0
	--											THEN CASE WHEN  ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) > OriginalTaxAmount_Amount 
	--											THEN OriginalTaxAmount_Amount
	--											ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) <=0
	--											THEN 0
	--											ELSE  ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--											END END
	--											ELSE CASE WHEN   ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) < OriginalTaxAmount_Amount
	--											THEN OriginalTaxAmount_Amount
	--											ELSE CASE WHEN  ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) > =OriginalTaxAmount_Amount 
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--											ELSE 0 
	--											END END	END
	--											ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount 
	--										END,										 
	--		UpdatedById = @CurrentUserId,
	--		UpdatedTime = @CurrentTime
	--		FROM 
	--		ReceivableInvoiceDetails 
	--		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--		INNER JOIN #TempReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #TempReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId
	--		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--		WHERE 
	--		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--		AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--		AND ReceivableInvoiceDetails.IsActive = 1


	UPDATE
		ReceiptApplicationReceivableDetails 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationReceivableDetails.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableDetails.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationReceivableDetails.TaxApplied_Currency,
		PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
		PreviousBookAmountApplied_Currency = ReceiptApplicationReceivableDetails.BookAmountApplied_Currency,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount,
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

	UPDATE
		ReceiptApplicationInvoices 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationInvoices.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationInvoices.TaxApplied_Currency,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationInvoices
	WHERE 
		ReceiptApplicationInvoices.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationInvoices.IsReApplication = 0;

	UPDATE
		ReceiptApplicationReceivableGroups 
	SET 
		PreviousAmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount,
		PreviousAmountApplied_Currency = ReceiptApplicationReceivableGroups.AmountApplied_Currency,
		PreviousTaxApplied_Amount = ReceiptApplicationReceivableGroups.TaxApplied_Amount,
		PreviousTaxApplied_Currency = ReceiptApplicationReceivableGroups.TaxApplied_Currency,
		PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableGroups.AdjustedWithHoldingTax_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceiptApplicationReceivableGroups
	WHERE 
		ReceiptApplicationReceivableGroups.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationReceivableGroups.IsReApplication = 0;

	UPDATE
			ReceiptApplicationInvoices 
		SET 
			AmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount - ReceiptApplicationInvoices.PreviousAmountApplied_Amount,
			TaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount - ReceiptApplicationInvoices.PreviousTaxApplied_Amount,
			PreviousAmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount - ReceiptApplicationInvoices.PreviousAmountApplied_Amount,
			PreviousAmountApplied_Currency = ReceiptApplicationInvoices.AmountApplied_Currency,
			PreviousTaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount - ReceiptApplicationInvoices.PreviousTaxApplied_Amount,
			PreviousTaxApplied_Currency = ReceiptApplicationInvoices.TaxApplied_Currency,
			AdjustedWithHoldingTax_Amount = ReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount - ReceiptApplicationInvoices.PreviousAdjustedWithHoldingTax_Amount,
			PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount - ReceiptApplicationInvoices.PreviousAdjustedWithHoldingTax_Amount,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
		FROM 
			ReceiptApplicationInvoices
		WHERE 
			ReceiptApplicationInvoices.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationInvoices.IsReApplication = 1;

	UPDATE
			ReceiptApplicationReceivableGroups 
		SET 
			AmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount - ReceiptApplicationReceivableGroups.PreviousAmountApplied_Amount,
			TaxApplied_Amount = ReceiptApplicationReceivableGroups.TaxApplied_Amount - ReceiptApplicationReceivableGroups.PreviousTaxApplied_Amount,
			PreviousAmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount - ReceiptApplicationReceivableGroups.PreviousAmountApplied_Amount,
			PreviousAmountApplied_Currency = ReceiptApplicationReceivableGroups.AmountApplied_Currency,
			PreviousTaxApplied_Amount = ReceiptApplicationReceivableGroups.TaxApplied_Amount - ReceiptApplicationReceivableGroups.PreviousTaxApplied_Amount,
			PreviousTaxApplied_Currency = ReceiptApplicationReceivableGroups.TaxApplied_Currency,
			AdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableGroups.AdjustedWithHoldingTax_Amount - ReceiptApplicationReceivableGroups.PreviousAdjustedWithHoldingTax_Amount,
			PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableGroups.AdjustedWithHoldingTax_Amount - ReceiptApplicationReceivableGroups.PreviousAdjustedWithHoldingTax_Amount,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
		FROM 
			ReceiptApplicationReceivableGroups
		WHERE 
			ReceiptApplicationReceivableGroups.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableGroups.IsReApplication = 1;
	

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
		WHERE 
			ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableTaxImpositions.IsActive = 1;

	SELECT 
		ReceivableTaxDetails.ReceivableDetailId, SUM(#TaxTemp.AmountApplied) AS TaxApplied
	INTO #TempTaxApplied
	FROM 
		#TaxTemp
		JOIN ReceivableTaxImpositions ON #TaxTemp.TaxImpositionId = ReceivableTaxImpositions.Id
		JOIN ReceivableTaxDetails ON ReceivableTaxImpositions.ReceivableTaxDetailId = ReceivableTaxDetails.Id AND ReceivableTaxDetails.IsActive=1
	WHERE ReceivableTaxImpositions.IsActive=1	
	GROUP BY ReceivableTaxDetails.ReceivableDetailId;

		SELECT
			ROW_NUMBER() OVER (ORDER BY ReceiptApplicationReceivableDetails.Id,ReceivableTaxImpositions.Amount_Amount,ReceivableTaxImpositions.Id) AS RowNumber,
			ReceivableTaxImpositions.Id AS TaxImpositionId,
			ReceiptApplicationReceivableDetails.Id AS ApplicationDetailId, 
			ReceivableTaxImpositions.EffectiveBalance_Amount + ISNULL(#TaxTemp.AmountApplied,0.0) AS TaxBalance,
			0.0 AS AmountToApply,
			ReceiptApplicationReceivableDetails.TaxApplied_Amount AS TaxApplied,
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
		ReceivableTaxImpositions SET Balance_Amount = (Balance_Amount + ISNULL(AmountApplied,0.0)),
	EffectiveBalance_Amount = (EffectiveBalance_Amount + ISNULL(AmountApplied,0.0)) - #TaxImpositions.AmountToApply,
	UpdatedById = @CurrentUserId,
	UpdatedTime = @CurrentTime
	FROM ReceivableTaxImpositions 
	INNER JOIN #TaxImpositions 
		ON ReceivableTaxImpositions.Id = #TaxImpositions.TaxImpositionId
	LEFT JOIN #TaxTemp
		ON #TaxTemp.TaxImpositionId = ReceivableTaxImpositions.Id
	WHERE ReceivableTaxImpositions.IsActive=1;

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

	UPDATE 
			ReceiptApplicationReceivableDetails 
	SET		AmountApplied_Amount = #TempApplicationReceivableDetails.AmountApplied_Amount, 
			TaxApplied_Amount = #TempApplicationReceivableDetails.TaxApplied_Amount,
			BookAmountApplied_Amount = #TempApplicationReceivableDetails.BookAmountApplied_Amount,
			AdjustedWithholdingTax_Amount = #TempApplicationReceivableDetails.AdjustedWithholdingTax_Amount,
			LeaseComponentAmountApplied_Amount = #TempApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
			NonLeaseComponentAmountApplied_Amount = #TempApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount
	FROM ReceiptApplicationReceivableDetails
	INNER JOIN ReceiptApplications 
		ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
	INNER JOIN #TempApplicationReceivableDetails
		ON ReceiptApplicationReceivableDetails.Id = #TempApplicationReceivableDetails.Id
		WHERE ReceiptApplications.ReceiptId = @ReceiptId
	AND ReceiptApplications.Id = @ApplicationId

	UPDATE
		ReceiptApplicationInvoices SET AmountApplied_Amount = #TempReceiptApplicationInvoices.AmountApplied_Amount, 
		TaxApplied_Amount = #TempReceiptApplicationInvoices.TaxApplied_Amount,
		AdjustedWithHoldingTax_Amount = #TempReceiptApplicationInvoices.AdjustedWithHoldingTax_Amount
	FROM 
	ReceiptApplicationInvoices
	INNER JOIN #TempReceiptApplicationInvoices
		ON ReceiptApplicationInvoices.Id = #TempReceiptApplicationInvoices.Id
		WHERE 
		ReceiptApplicationInvoices.ReceiptApplicationId = @ApplicationId

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
			TaxBalance_Amount, EffectiveTaxBalance_Amount, WithHoldingTaxBalance) AS
		(			
			SELECT
				InvoiceId.ReceivableInvoiceId,
				SUM(ReceivableInvoiceDetails.Balance_Amount) Balance_Amount, 
				SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) EffectiveBalance_Amount,
				SUM(ReceivableInvoiceDetails.TaxBalance_Amount) TaxBalance_Amount, 
				SUM(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) EffectiveTaxBalance_Amount,
				SUM(ISNULL(ReceivableDetailsWithholdingTaxDetails.Balance_Amount,0)) WithHoldingTaxBalance
			FROM #InvoiceIds AS InvoiceId				
			JOIN ReceivableInvoiceDetails ON InvoiceId.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId 
				AND ReceivableInvoiceDetails.IsActive = 1
			LEFT JOIN ReceivableDetailsWithholdingTaxDetails ON ReceivableInvoiceDetails.ReceivableDetailId=ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId AND ReceivableDetailsWithholdingTaxDetails.IsActive=1
			GROUP BY InvoiceId.ReceivableInvoiceId				
		)
		UPDATE    
			ReceivableInvoices     
		SET     
			Balance_Amount = InvoiceDetails.Balance_Amount,    
			EffectiveBalance_Amount = InvoiceDetails.EffectiveBalance_Amount,    
			TaxBalance_Amount = ISNULL(InvoiceDetails.TaxBalance_Amount, 0.00),
			EffectiveTaxBalance_Amount = ISNULL(InvoiceDetails.EffectiveTaxBalance_Amount, 0.00),
			WithHoldingTaxBalance_Amount = ISNULL(InvoiceDetails.WithHoldingTaxBalance, 0.00),
			UpdatedById = @CurrentUserId, 
			UpdatedTime = @CurrentTime     
		FROM     
			ReceivableInvoices    
			JOIN  CTE_InvoiceDetails AS InvoiceDetails ON InvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id	
			
	    SELECT StatementInvoiceId 
		INTO #StatementInvoicesOfReceivableInvoices
		FROM #InvoiceIds RI
		INNER JOIN ReceivableInvoiceStatementAssociations RISA ON RI.ReceivableInvoiceId = RISA.ReceivableInvoiceId
        GROUP BY StatementInvoiceId

		IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
		BEGIN
		SELECT 
			SRI.StatementInvoiceId,
			Balance_Amount = ISNULL(SUM(RI.Balance_Amount), 0),
			TaxBalance_Amount = ISNULL(SUM(TaxBalance_Amount),0),
			EffectiveBalance_Amount = ISNULL(SUM(RI.EffectiveBalance_Amount), 0),
			EffectiveTaxBalance_Amount = ISNULL(SUM(EffectiveTaxBalance_Amount),0),
			WithHoldingTaxBalance_Amount = ISNULL(SUM(RI.WithHoldingTaxBalance_Amount), 0)
		INTO #StatementInvoicesUpdateAmount
		FROM #StatementInvoicesOfReceivableInvoices SRI 
		INNER JOIN ReceivableInvoiceStatementAssociations RSI ON SRI.StatementInvoiceId = RSI.StatementInvoiceID
		INNER JOIN ReceivableInvoices RI ON RSI.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
		GROUP BY SRI.StatementInvoiceId

		UPDATE RI
		SET 
		   Balance_Amount =  SRI.Balance_Amount,
		   TaxBalance_Amount = SRI.TaxBalance_Amount,
		   EffectiveBalance_Amount = SRI.EffectiveBalance_Amount,
		   EffectiveTaxBalance_Amount = SRI.EffectiveTaxBalance_Amount,
		   WithHoldingTaxBalance_Amount = SRI.WithHoldingTaxBalance_Amount,
		   UpdatedById = @CurrentUserId, 
		   UpdatedTime = @CurrentTime
		FROM ReceivableInvoices RI
		INNER JOIN #StatementInvoicesUpdateAmount SRI ON RI.Id = SRI.StatementInvoiceId
		END
	
		--PRINT 'The END'			
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
	DROP TABLE #StatementInvoicesOfReceivableInvoices

--ROLLBACK TRAN T
END

GO
