SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceivablesForReceiptApplicationForPostByFile]
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
SET NOCOUNT ON;
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

	DECLARE @AnyInActiveApplication BIT = 0; 

	IF @IsReversal = 1
	BEGIN

		INSERT INTO #TempApplicationReceivableDetails
		SELECT 
				ReceiptApplicationReceivableDetails.Id, 
				ReceiptApplicationReceivableDetails.AmountApplied_Amount, 
				ReceiptApplicationReceivableDetails.TaxApplied_Amount,
				ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
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
				ReceiptApplicationInvoices.TaxApplied_Amount
		FROM 
			ReceiptApplicationInvoices
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationInvoices.ReceiptApplicationId
		WHERE 
		ReceiptApplications.ReceiptId = @ReceiptId
		AND ReceiptApplications.Id = @ApplicationId;

		UPDATE
			ReceiptApplicationReceivableDetails 
		SET 
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0, BookAmountApplied_Amount = 0.0 ,
			LeaseComponentAmountApplied_Amount = 0.0, NonLeaseComponentAmountApplied_Amount = 0.0
		FROM 
			ReceiptApplicationReceivableDetails
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId;

		UPDATE
			ReceiptApplicationInvoices 
		SET 
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0
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
	END
	ELSE IF EXISTS(SELECT 1 FROM ReceiptApplicationReceivableDetails
	WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId AND ReceiptApplicationReceivableDetails.IsActive = 0)
	BEGIN
		SET @AnyInActiveApplication = 1;

		INSERT INTO #TempApplicationReceivableDetails
		SELECT 
			ReceiptApplicationReceivableDetails.Id, 
			ReceiptApplicationReceivableDetails.AmountApplied_Amount, 
			ReceiptApplicationReceivableDetails.TaxApplied_Amount,
			ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
			ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
			ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount
		FROM 
			ReceiptApplicationReceivableDetails
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId
			AND ReceiptApplicationReceivableDetails.IsActive = 0;

		INSERT INTO #TempReceiptApplicationInvoices
		SELECT
			ReceiptApplicationInvoices.Id, 
			ReceiptApplicationInvoices.AmountApplied_Amount, 
			ReceiptApplicationInvoices.TaxApplied_Amount
		FROM 
			ReceiptApplicationInvoices
			INNER JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationInvoices.ReceiptApplicationId
		WHERE 
			ReceiptApplications.ReceiptId = @ReceiptId
			AND ReceiptApplications.Id = @ApplicationId
			AND ReceiptApplicationInvoices.IsActive = 0;

		UPDATE
			ReceiptApplicationReceivableDetails 
		SET 
			AmountApplied_Amount = 0.0, TaxApplied_Amount = 0.0,BookAmountApplied_Amount = 0.0,
			LeaseComponentAmountApplied_Amount = 0.0, NonLeaseComponentAmountApplied_Amount = 0.0
			FROM ReceiptApplicationReceivableDetails 
		WHERE 
			ReceiptApplicationReceivableDetails.IsActive = 0
			AND ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId;
	END


	IF(@UpdateBalance = 1)
	BEGIN
		IF(@IsFromBatch = 1)
		BEGIN
		
	UPDATE 
		ReceivableDetails 
			SET Balance_Amount = Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount,
			EffectiveBookBalance_Amount = EffectiveBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,												
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
			LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
			NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
			FROM 
			ReceivableDetails 
			INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
			WHERE 
			ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableDetails.IsReApplication = 1
			AND ReceivableDetails.IsActive=1
		END
		ELSE
		BEGIN 

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
							END
										END
	ELSE
	BEGIN

		UPDATE 
		ReceivableDetails 
		SET Balance_Amount = Balance_Amount, 
		EffectiveBookBalance_Amount =EffectiveBookBalance_Amount, 
		EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
		LeaseComponentBalance_Amount = LeaseComponentBalance_Amount,
		NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM 
		ReceivableDetails 
		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
		AND ReceiptApplicationReceivableDetails.IsReApplication = 1
		AND ReceivableDetails.IsActive=1
	END

	--UPDATE 
	--	ReceivableDetails 
	--SET 
	--	Balance_Amount = CASE WHEN @UpdateBalance = 1 
	--						THEN CASE WHEN @IsFromBatch = 1
	--							THEN Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--							ELSE Balance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)) 
	--						END
	--						ELSE Balance_Amount END, 
	--	EffectiveBookBalance_Amount =  CASE WHEN @UpdateBalance = 1 
	--									THEN CASE WHEN @IsFromBatch = 1
	--										THEN EffectiveBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount
	--										ELSE EffectiveBookBalance_Amount - (ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - ISNULL(PreviousBookAmountApplied_Amount, 0.0)) 
	--									END
	--									ELSE EffectiveBookBalance_Amount END, 
	--	EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--FROM 
	--	ReceivableDetails 
	--	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 1
	
	IF(@UpdateBalance = 1)
	BEGIN
		IF(@IsReversal = 1)
		BEGIN
			UPDATE 	ReceivableDetails 
			SET Balance_Amount = Balance_Amount + ISNULL(PreviousAmountApplied_Amount, 0.0),									
			EffectiveBookBalance_Amount = EffectiveBookBalance_Amount + ISNULL(PreviousBookAmountApplied_Amount, 0.0),								         		
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
			LeaseComponentBalance_Amount = LeaseComponentBalance_Amount + ISNULL(PrevLeaseComponentAmountApplied_Amount, 0.0),
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
				            END
		ELSE
		BEGIN
			UPDATE 	ReceivableDetails 
			SET Balance_Amount = Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount,
			EffectiveBookBalance_Amount =EffectiveBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
			EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
			LeaseComponentBalance_Amount = LeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.PrevLeaseComponentAmountApplied_Amount,
			NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.PrevNonLeaseComponentAmountApplied_Amount,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
			FROM ReceivableDetails 
			INNER JOIN ReceiptApplicationReceivableDetails 
			ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
			WHERE 
			ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableDetails.IsReApplication = 0
			AND ReceivableDetails.IsActive=1;
										END
	END
	ELSE
	BEGIN
		UPDATE 	ReceivableDetails 
			SET Balance_Amount = Balance_Amount, 
			EffectiveBookBalance_Amount = EffectiveBookBalance_Amount,
		EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
		LeaseComponentBalance_Amount = LeaseComponentBalance_Amount,
		NonLeaseComponentBalance_Amount = NonLeaseComponentBalance_Amount,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableDetails 
	INNER JOIN ReceiptApplicationReceivableDetails 
		ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	WHERE 
		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableDetails.IsReApplication = 0
			AND ReceivableDetails.IsActive=1;
	END

	--PRINT 'Update Recv Details'

	--UPDATE 
	--	ReceivableDetails 
	--SET 
	--	Balance_Amount = CASE WHEN @UpdateBalance = 1
	--						THEN CASE WHEN @IsReversal = 1
	--							THEN Balance_Amount + ISNULL(PreviousAmountApplied_Amount, 0.0)
	--							ELSE Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--			            END
	--						ELSE Balance_Amount END, 
	--	EffectiveBookBalance_Amount = CASE WHEN @UpdateBalance = 1
	--									THEN CASE WHEN @IsReversal = 1
	--										THEN EffectiveBookBalance_Amount + ISNULL(PreviousBookAmountApplied_Amount, 0.0)
	--							         	ELSE EffectiveBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount
	--									END
	--									ELSE EffectiveBookBalance_Amount END,
	--	EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--FROM ReceivableDetails 
	--INNER JOIN ReceiptApplicationReceivableDetails 
	--	ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 0;

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

	--PRINT 'Update Receivables'

	--IF(@IsReversal = 1)
	--BEGIN
	--	IF(@UpdateBalance = 1)
	--	BEGIN
	--		UPDATE ReceivableInvoiceDetails 
	--SET 
	--			Balance_Amount = ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount,
	--	EffectiveBalance_Amount = ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount,
	--			TaxBalance_Amount = ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount,							
	--	EffectiveTaxBalance_Amount = ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount,
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
 --   END
	--	ELSE
	--	BEGIN 
	--		UPDATE	ReceivableInvoiceDetails 
	--		SET Balance_Amount = ReceivableInvoiceDetails.Balance_Amount,
	--		EffectiveBalance_Amount = ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.AmountApplied_Amount,
	--		TaxBalance_Amount = ReceivableInvoiceDetails.TaxBalance_Amount,
	--		EffectiveTaxBalance_Amount = ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount,
	--		UpdatedById = @CurrentUserId,
	--		UpdatedTime = @CurrentTime
	--		FROM ReceivableInvoiceDetails 
	--		INNER JOIN ReceiptApplicationReceivableDetails 
	--		ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--		INNER JOIN ReceivableInvoices
	--		ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--		WHERE 
	--		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--		AND ReceiptApplicationReceivableDetails.IsReApplication = 1
	--		AND ReceivableInvoices.IsDummy = 0
	--		AND ReceivableInvoices.IsActive = 1
	--		AND ReceivableInvoiceDetails.IsActive = 1
	--	END
	--END

	--BEGIN
	--UPDATE
	--	ReceivableInvoiceDetails 
	--SET 
	--	Balance_Amount = CASE WHEN @UpdateBalance = 1
	--							THEN ReceivableInvoiceDetails.Balance_Amount + ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount
	--							ELSE ReceivableInvoiceDetails.Balance_Amount 
	--						END,
	--	EffectiveBalance_Amount = ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount,
	--	TaxBalance_Amount = CASE WHEN @UpdateBalance = 1
	--							THEN ReceivableInvoiceDetails.TaxBalance_Amount + ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount
	--							ELSE ReceivableInvoiceDetails.TaxBalance_Amount 
	--						END,
	--	EffectiveTaxBalance_Amount = ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount,
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
 --   END

	--IF(@IsReversal = 1)
	--BEGIN
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
	--	AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
	--END
	--ELSE
	--BEGIN
	--	INSERT INTO #TempReceivableInvoiceDetails
	--	SELECT  
	--	ReceivableInvoiceDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
	--	ReceivableInvoiceDetails.ReceivableDetailId AS ReceivableDetailId,
	--	CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0
	--				THEN CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount =  0 OR ReceivableInvoiceDetails.EffectiveBalance_Amount >= ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--					THEN ReceiptApplicationReceivableDetails.AmountApplied_Amount 
	--					ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount END
	--				ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveBalance_Amount >= (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(AmountApplied_Amount, 0.0)) 
	--					THEN ReceiptApplicationReceivableDetails.AmountApplied_Amount  
	--			 ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0) END END AS AmountApplied_Amount,
	--	CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0
	--				THEN CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount =  0 OR  ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount 
	--					ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount END
	--				ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(TaxApplied_Amount, 0.0))
	--					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--				ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0) END END AS TaxApplied_Amount,
	--		ReceiptApplicationReceivableDetails.AmountApplied_Currency AS Currency
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
	--END

	--INSERT INTO #TempReceivableInvoiceDetails
	--SELECT  CASE WHEN @IsReversal = 0 THEN ReceivableInvoiceDetails.ReceivableInvoiceId ELSE ReceiptApplicationReceivableDetails.ReceivableInvoiceId END AS ReceivableInvoiceId,
	--		ReceivableInvoiceDetails.ReceivableDetailId AS ReceivableDetailId,
	--		CASE WHEN @IsReversal = 1 THEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount
	--			ELSE CASE WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount = 0
	--				THEN CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount =  0 OR ReceivableInvoiceDetails.EffectiveBalance_Amount >= ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--					THEN ReceiptApplicationReceivableDetails.AmountApplied_Amount 
	--					ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount END
	--				ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveBalance_Amount >= (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0)) 
	--					THEN ReceiptApplicationReceivableDetails.AmountApplied_Amount  
	--					ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0) END END 
	--			END AS AmountApplied_Amount,
	--		CASE WHEN @IsReversal = 1 THEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount
	--			ELSE CASE WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount = 0
	--				THEN CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount =  0 OR  ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount 
	--					ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount END
	--				ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0))
	--					THEN ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--					ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0) END END 
	--			END AS TaxApplied_Amount,
	--		ReceiptApplicationReceivableDetails.AmountApplied_Currency AS Currency
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
	--	AND ReceivableInvoiceDetails.OriginalAmount_Amount <> 0
	--	AND (@IsReversal = 0 OR ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL)
		
	--PRINT 'Insert Into Temp'

	--IF(@UpdateBalance = 1)
	--BEGIN 
	--	IF(@IsReversal = 1)
	--	BEGIN
	--		UPDATE ReceivableInvoiceDetails
	--		SET Balance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0
	--								THEN ReceivableInvoiceDetails.Balance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--								ELSE ReceivableInvoiceDetails.Balance_Amount
	--								 END,								
	--		EffectiveBalance_Amount =CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--										ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount 
	--									END,									
	--		TaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0
	--									THEN ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--									ELSE ReceivableInvoiceDetails.TaxBalance_Amount
	--								END,
	--		EffectiveTaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
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
	--							END
	--	ELSE
	--	BEGIN
	--		UPDATE ReceivableInvoiceDetails
	--		SET 
	--		Balance_Amount = CASE WHEN #TempReceivableInvoiceDetails.AmountApplied_Amount != 0
	--								THEN ReceivableInvoiceDetails.Balance_Amount - #TempReceivableInvoiceDetails.AmountApplied_Amount
	--								ELSE ReceivableInvoiceDetails.Balance_Amount
	--						 END,
	--		EffectiveBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0
	--									THEN CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveBalance_Amount >= ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										ELSE 0 END
	--									ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveBalance_Amount >= (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(AmountApplied_Amount, 0.0)) 
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(AmountApplied_Amount, 0.0)) 
	--										ELSE 0 END
	--								END,
	--		TaxBalance_Amount = CASE WHEN #TempReceivableInvoiceDetails.TaxApplied_Amount != 0
	--								THEN ReceivableInvoiceDetails.TaxBalance_Amount - #TempReceivableInvoiceDetails.TaxApplied_Amount
	--								ELSE ReceivableInvoiceDetails.TaxBalance_Amount
	--							END,						 
	--		EffectiveTaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0
	--										THEN CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount 
	--											ELSE 0 END
	--										ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(TaxApplied_Amount, 0.0))
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(TaxApplied_Amount, 0.0)) 
	--											ELSE 0 END
	--									END, 
	--		UpdatedById = @CurrentUserId,
	--		UpdatedTime = @CurrentTime
	--		FROM 
	--		ReceivableInvoiceDetails 
	--		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--		INNER JOIN #TempReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #TempReceivableInvoiceDetails.ReceivableDetailId
	--		AND ReceivableInvoiceDetails.ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId
	--		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--		WHERE 
	--		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--		AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--		AND ReceivableInvoiceDetails.IsActive = 1
	--							END
	--						END
	--ELSE
	--IF(@IsReversal = 1)
	--BEGIN 
	--	UPDATE ReceivableInvoiceDetails
	--	SET Balance_Amount = ReceivableInvoiceDetails.Balance_Amount,
	--	EffectiveBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount != 0
	--									THEN ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(AmountApplied_Amount, 0.0)
	--									ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount END,									
	--	TaxBalance_Amount = ReceivableInvoiceDetails.TaxBalance_Amount,

	--	EffectiveTaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount != 0
	--									THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(TaxApplied_Amount, 0.0)
	--									ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount 
	--								END,
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--	FROM 
	--	ReceivableInvoiceDetails 
	--	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--	INNER JOIN #TempReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #TempReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId
	--	INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--	WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--	AND ReceivableInvoiceDetails.IsActive = 1
	--								END
	--ELSE
	--BEGIN
	--	UPDATE ReceivableInvoiceDetails
	--	SET Balance_Amount = ReceivableInvoiceDetails.Balance_Amount,
	--	EffectiveBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0
	--									THEN CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveBalance_Amount >= ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										ELSE 0 END
	--									ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveBalance_Amount >= (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(AmountApplied_Amount, 0.0)) 
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(AmountApplied_Amount, 0.0)) 
	--										ELSE 0 END
	--								END,
	--	TaxBalance_Amount = ReceivableInvoiceDetails.TaxBalance_Amount,
	--	EffectiveTaxBalance_Amount =CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0
	--										THEN CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount 
	--											ELSE 0 END
	--										ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(TaxApplied_Amount, 0.0))
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(TaxApplied_Amount, 0.0)) 
	--											ELSE 0 END
	--									END, 
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--FROM 
	--	ReceivableInvoiceDetails 
	--	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--	INNER JOIN #TempReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #TempReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId
	--	INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--	AND ReceivableInvoiceDetails.IsActive = 1
	--END
	

	--PRINT 'Update Receivable Invoice Details'
	--UPDATE
	--	ReceivableInvoiceDetails
	--SET 
	--	Balance_Amount = CASE WHEN @UpdateBalance = 1
 --    						THEN CASE WHEN @IsReversal = 1 
	--							THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount != 0
	--								THEN ReceivableInvoiceDetails.Balance_Amount + ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0)
	--								ELSE ReceivableInvoiceDetails.Balance_Amount
	--							END
	--							ELSE CASE WHEN #TempReceivableInvoiceDetails.AmountApplied_Amount != 0
	--								THEN ReceivableInvoiceDetails.Balance_Amount - #TempReceivableInvoiceDetails.AmountApplied_Amount
	--								ELSE ReceivableInvoiceDetails.Balance_Amount
	--							END
	--						END
	--					 ELSE ReceivableInvoiceDetails.Balance_Amount END,
	--	EffectiveBalance_Amount = CASE WHEN @IsReversal = 1 
	--								THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount != 0
	--									THEN ReceivableInvoiceDetails.EffectiveBalance_Amount + ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0)
	--									ELSE ReceivableInvoiceDetails.EffectiveBalance_Amount 
	--								END
	--								ELSE CASE WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount = 0
	--									THEN CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveBalance_Amount >= ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--										ELSE 0 END
	--									--THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
	--									ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveBalance_Amount >= (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0)) 
	--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(ReceivableAmountAppliedToInvoice_Amount, 0.0)) 
	--										ELSE 0 END
	--									--ReceivableInvoiceDetails.EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)) 
	--								END END,
	--	TaxBalance_Amount = CASE WHEN @UpdateBalance = 1
 --    						THEN CASE WHEN @IsReversal = 1 
	--							THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount != 0
	--								THEN ReceivableInvoiceDetails.TaxBalance_Amount + ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0)
	--								ELSE ReceivableInvoiceDetails.TaxBalance_Amount
	--							END
	--							ELSE CASE WHEN #TempReceivableInvoiceDetails.TaxApplied_Amount != 0
	--								THEN ReceivableInvoiceDetails.TaxBalance_Amount - #TempReceivableInvoiceDetails.TaxApplied_Amount
	--								ELSE ReceivableInvoiceDetails.TaxBalance_Amount
	--							END
	--						END
	--					 ELSE ReceivableInvoiceDetails.TaxBalance_Amount END,
	--	EffectiveTaxBalance_Amount = CASE WHEN @IsReversal = 1
	--									THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount != 0
	--										THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount + ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0)
	--										ELSE ReceivableInvoiceDetails.EffectiveTaxBalance_Amount 
	--									END
	--									ELSE CASE WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount = 0
	--										THEN CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount = 0 OR ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount 
	--											ELSE 0 END
	--									--ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount
	--										ELSE CASE WHEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount >= (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0))
	--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(ReceivableTaxAppliedToInvoice_Amount, 0.0)) 
	--											ELSE 0 END
	--										-- ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - (ReceiptApplicationReceivableDetails.TaxApplied_Amount - ISNULL(PreviousTaxApplied_Amount, 0.0)) 
	--									END END, 
	--	UpdatedById = @CurrentUserId,
	--	UpdatedTime = @CurrentTime
	--FROM 
	--	ReceivableInvoiceDetails 
	--	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	--	INNER JOIN #TempReceivableInvoiceDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #TempReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.ReceivableInvoiceId = #TempReceivableInvoiceDetails.ReceivableInvoiceId
	--	INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	--WHERE 
	--	ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	--	AND ReceiptApplicationReceivableDetails.IsReApplication = 0
	--	AND ReceivableInvoiceDetails.OriginalAmount_Amount <> 0
	--	AND ReceivableInvoices.IsDummy = 0
	--	AND ReceivableInvoices.IsActive = 1
	--	AND ReceivableInvoiceDetails.IsActive = 1

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

	IF (@IsFromBatch = 0 AND @IsReversal = 0)
	BEGIN
		UPDATE
			ReceiptApplicationReceivableDetails 
		SET 
			AmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount - ReceiptApplicationReceivableDetails.PreviousAmountApplied_Amount,
			TaxApplied_Amount = ReceiptApplicationReceivableDetails.TaxApplied_Amount - ReceiptApplicationReceivableDetails.PreviousTaxApplied_Amount,
			PreviousAmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount - ReceiptApplicationReceivableDetails.PreviousAmountApplied_Amount,
			PreviousAmountApplied_Currency = ReceiptApplicationReceivableDetails.AmountApplied_Currency,
			PreviousTaxApplied_Amount = ReceiptApplicationReceivableDetails.TaxApplied_Amount - ReceiptApplicationReceivableDetails.PreviousTaxApplied_Amount,
			PreviousTaxApplied_Currency = ReceiptApplicationReceivableDetails.TaxApplied_Currency,
			BookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - ReceiptApplicationReceivableDetails.PreviousBookAmountApplied_Amount,
			BookAmountApplied_Currency = ReceiptApplicationReceivableDetails.BookAmountApplied_Currency,
			PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - ReceiptApplicationReceivableDetails.PreviousBookAmountApplied_Amount,
			PreviousBookAmountApplied_Currency = ReceiptApplicationReceivableDetails.BookAmountApplied_Currency,
			LeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount - ReceiptApplicationReceivableDetails.PrevLeaseComponentAmountApplied_Amount,
			LeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Currency,
			NonLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount - ReceiptApplicationReceivableDetails.PrevNonLeaseComponentAmountApplied_Amount,
			NonLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Currency,
			PrevLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount - ReceiptApplicationReceivableDetails.PrevLeaseComponentAmountApplied_Amount,
			PrevLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Currency,
			PrevNonLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount - ReceiptApplicationReceivableDetails.PrevNonLeaseComponentAmountApplied_Amount,
			PrevNonLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Currency,
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
		FROM 
			ReceiptApplicationReceivableDetails
		WHERE 
			ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableDetails.IsReApplication = 1;
	END

--	IF(@IsReversal = 0)
--	BEGIN 
--		IF(@UpdateBalance = 1) 
--	BEGIN 
--			UPDATE ReceivableInvoiceDetails 
--			SET Balance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount < ReceivableInvoiceDetails.Balance_Amount
--									THEN ReceivableInvoiceDetails.Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
--									ELSE 0 END,
--			EffectiveBalance_Amount = CASE WHEN @IsFromBatch = 1 
--											THEN ReceivableInvoiceDetails.EffectiveBalance_Amount
--										WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount < ReceivableInvoiceDetails.EffectiveBalance_Amount
--											THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
--											ELSE 0 END,
--			TaxBalance_Amount = CASE WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount < ReceivableInvoiceDetails.TaxBalance_Amount
--									THEN ReceivableInvoiceDetails.TaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount
--									ELSE 0 END,
--			EffectiveTaxBalance_Amount = CASE WHEN @IsFromBatch = 1 THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--											WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount < ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--											THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount
--											ELSE 0 END,
--			UpdatedById = @CurrentUserId,
--			UpdatedTime = @CurrentTime
--			FROM 
--		ReceivableInvoiceDetails 
--			INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
--			INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
--			WHERE 
--			ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
--			AND ReceiptApplicationReceivableDetails.IsReApplication = 1
--			AND ReceivableInvoices.IsDummy = 0
--			AND ReceivableInvoices.IsActive = 1
--			AND ReceivableInvoiceDetails.IsActive = 1;
--		END 
--		ELSE
--		BEGIN
--			UPDATE ReceivableInvoiceDetails 
--	SET 
--			Balance_Amount = ReceivableInvoiceDetails.Balance_Amount,
--		EffectiveBalance_Amount = CASE WHEN @IsFromBatch = 1 
--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount
--									WHEN ReceiptApplicationReceivableDetails.AmountApplied_Amount < ReceivableInvoiceDetails.EffectiveBalance_Amount
--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
--										ELSE 0 END,
--			TaxBalance_Amount = ReceivableInvoiceDetails.TaxBalance_Amount,
--		EffectiveTaxBalance_Amount = CASE WHEN @IsFromBatch = 1 THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--										WHEN ReceiptApplicationReceivableDetails.TaxApplied_Amount < ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--										THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.TaxApplied_Amount
--										ELSE 0 END,
--		UpdatedById = @CurrentUserId,
--		UpdatedTime = @CurrentTime
--	FROM 
--		ReceivableInvoiceDetails 
--		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
--		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
--	WHERE 
--		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
--		AND ReceiptApplicationReceivableDetails.IsReApplication = 1
--		AND ReceivableInvoices.IsDummy = 0
--		AND ReceivableInvoices.IsActive = 1
--		AND ReceivableInvoiceDetails.IsActive = 1;
--END 
--	END

	--PRINT 'UPDATE Receivable Invoice Details'
--	UPDATE
--		ReceivableInvoiceDetails 
--	SET 
--		Balance_Amount = CASE WHEN @UpdateBalance = 1
--							THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount < ReceivableInvoiceDetails.Balance_Amount
--								THEN ReceivableInvoiceDetails.Balance_Amount - ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount
--								ELSE 0 END
--							ELSE ReceivableInvoiceDetails.Balance_Amount END,
--		EffectiveBalance_Amount = CASE WHEN @IsFromBatch = 1 
--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount
--									WHEN ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount < ReceivableInvoiceDetails.EffectiveBalance_Amount
--										THEN ReceivableInvoiceDetails.EffectiveBalance_Amount - ReceiptApplicationReceivableDetails.ReceivableAmountAppliedToInvoice_Amount
--										ELSE 0 END,
--		TaxBalance_Amount =  CASE WHEN @UpdateBalance = 1
--								THEN CASE WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount < ReceivableInvoiceDetails.TaxBalance_Amount
--								THEN ReceivableInvoiceDetails.TaxBalance_Amount - ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount
--								ELSE 0 END
--								ELSE ReceivableInvoiceDetails.TaxBalance_Amount END,
--		EffectiveTaxBalance_Amount = CASE WHEN @IsFromBatch = 1 THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--										WHEN ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount < ReceivableInvoiceDetails.EffectiveTaxBalance_Amount
--										THEN ReceivableInvoiceDetails.EffectiveTaxBalance_Amount - ReceiptApplicationReceivableDetails.ReceivableTaxAppliedToInvoice_Amount
--										ELSE 0 END,
--		UpdatedById = @CurrentUserId,
--		UpdatedTime = @CurrentTime
--	FROM 
--		ReceivableInvoiceDetails 
--		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
--		INNER JOIN ReceivableInvoices ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
--	WHERE 
--		ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
--		AND ReceiptApplicationReceivableDetails.IsReApplication = 1
--		AND ReceivableInvoiceDetails.OriginalAmount_Amount <> 0
--		AND ReceivableInvoices.IsDummy = 0
--		AND ReceivableInvoices.IsActive = 1
--		AND ReceivableInvoiceDetails.IsActive = 1;
--END 

		--PRINT 'UPDATE Receivable Invoice Details'				

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

	IF @IsFromBatch = 0
	BEGIN
		UPDATE
			ReceiptApplicationInvoices 
		SET 
			AmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount - ReceiptApplicationInvoices.PreviousAmountApplied_Amount,
			TaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount - ReceiptApplicationInvoices.PreviousTaxApplied_Amount,
			PreviousAmountApplied_Amount = ReceiptApplicationInvoices.AmountApplied_Amount - ReceiptApplicationInvoices.PreviousAmountApplied_Amount,
			PreviousAmountApplied_Currency = ReceiptApplicationInvoices.AmountApplied_Currency,
			PreviousTaxApplied_Amount = ReceiptApplicationInvoices.TaxApplied_Amount - ReceiptApplicationInvoices.PreviousTaxApplied_Amount,
			PreviousTaxApplied_Currency = ReceiptApplicationInvoices.TaxApplied_Currency,
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
			UpdatedById = @CurrentUserId,
			UpdatedTime = @CurrentTime
		FROM 
			ReceiptApplicationReceivableGroups
		WHERE 
			ReceiptApplicationReceivableGroups.ReceiptApplicationId = @ApplicationId
			AND ReceiptApplicationReceivableGroups.IsReApplication = 1;
	END

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
	ELSE
	BEGIN
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

	IF @IsReversal = 0
	BEGIN
		UPDATE ReceiptApplicationReceivableTaxImpositions
		SET 
			AmountPosted_Amount = 0, 
			IsActive = 0,
			UpdatedById = @CurrentUserId, 
			UpdatedTime = @CurrentTime 
		FROM 
			ReceiptApplicationReceivableTaxImpositions
			JOIN #TaxImpositions ON #TaxImpositions.TaxImpositionId = ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId
			JOIN #TempId ON #TempId.ReceiptApplicationId = ReceiptApplicationReceivableTaxImpositions.ReceiptApplicationId
		WHERE 
			#TaxImpositions.IsReApplication = 1
			AND ReceiptApplicationReceivableTaxImpositions.IsActive = 1
	END	 

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

		IF (@AnyInActiveApplication = 1 OR @IsReversal = 1)
		BEGIN
			UPDATE 
					ReceiptApplicationReceivableDetails SET AmountApplied_Amount = #TempApplicationReceivableDetails.AmountApplied_Amount, 
					TaxApplied_Amount = #TempApplicationReceivableDetails.TaxApplied_Amount,
					BookAmountApplied_Amount = #TempApplicationReceivableDetails.BookAmountApplied_Amount,
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
					TaxApplied_Amount = #TempReceiptApplicationInvoices.TaxApplied_Amount
			FROM 
			ReceiptApplicationInvoices
			INNER JOIN #TempReceiptApplicationInvoices
				ON ReceiptApplicationInvoices.Id = #TempReceiptApplicationInvoices.Id
				WHERE 
				ReceiptApplicationInvoices.ReceiptApplicationId = @ApplicationId

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

--ROLLBACK TRAN T
END


GO
