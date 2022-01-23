SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[EvaluatePromises]
(
	@CustomerId BIGINT,
	@PaymentPromiseStatusOpen NVARCHAR(6),
	@PaymentPromiseStatusKept NVARCHAR(6),
	@PaymentPromiseStatusBroken NVARCHAR(6),
	@ReceiptStatusPosted NVARCHAR(15),
	@EntityTypeCT NVARCHAR(2),
	@ProcessThroughDate DATE,
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET,
	@AccessibleLegalEntities CollectionsJobLegalEntityId READONLY
)
AS
BEGIN

	CREATE TABLE #OpenPTP
	(
		RowNumber BIGINT IDENTITY(1,1) PRIMARY KEY,
		PaymentPromiseId BIGINT NOT NULL,
		ActivityForCollectionWorkListId BIGINT NOT NULL,
		CustomerId BIGINT NOT NULL,
		RemainingBalance DECIMAL(16,2) NOT NULL,
		PromiseDate DATE NOT NULL,
		CreatedTime DATETIMEOFFSET NOT NULL
	)

	CREATE TABLE #PTPContract
	(
		RowNumber BIGINT IDENTITY(1,1) PRIMARY KEY,
		PaymentPromiseId BIGINT NOT NULL,
		ContractId BIGINT NOT NULL
	)

	CREATE NONCLUSTERED INDEX IX_Temp_PTPContract_PaymentPromiseId ON #PTPContract(PaymentPromiseId);

	CREATE TABLE #PTPReceipts
	(
		RowNumber BIGINT IDENTITY(1,1) PRIMARY KEY,
		CustomerId BIGINT NOT NULL,			
		ContractId BIGINT NOT NULL,
		ReceiptId BIGINT NOT NULL,
		ReceivedCurrency NVARCHAR(3) NOT NULL,
		RemainingBalance DECIMAL(16,2) NOT NULL,
		ReceivedDate DATE NOT NULL,
		CreatedTime DATETIMEOFFSET NOT NULL
	)

	CREATE NONCLUSTERED INDEX IX_Temp_PTPReceipts_CustomerId_ContractId ON #PTPReceipts(CustomerId, ContractId);

	CREATE TABLE #PTPApplicationData
	(
		PaymentPromiseId BIGINT NOT NULL,
		CustomerId BIGINT NOT NULL,			
		ContractId BIGINT NOT NULL,
		ReceiptId BIGINT NOT NULL,
		AmountApplied_Amount DECIMAL(16,2) NOT NULL,
		AmountApplied_Currency NVARCHAR(3) NOT NULL,
	)

	-- Feth all the PTP which needs to be processed in open state..
	INSERT INTO #OpenPTP
		(
			PaymentPromiseId,
			ActivityForCollectionWorkListId,
			CustomerId,			
			RemainingBalance,
			PromiseDate,
			CreatedTime
		)
		SELECT DISTINCT
				PaymentPromises.Id,
				ActivityForCollectionWorkLists.Id,
				CollectionWorkLists.CustomerId,
				PaymentPromises.Amount_Amount,
				PaymentPromises.PromiseDate,
				PaymentPromises.CreatedTime
			FROM PaymentPromises
				INNER JOIN ActivityForCollectionWorkLists ON PaymentPromises.ActivityId = ActivityForCollectionWorkLists.Id -- ActivityId is not there in ActivityForCollectionWorkLists table.
				INNER JOIN CollectionWorkLists ON ActivityForCollectionWorkLists.CollectionWorkListId = CollectionWorkLists.Id
				INNER JOIN PTPContracts ON ActivityForCollectionWorkLists.Id = PTPContracts.ActivityForCollectionWorkListId
				INNER JOIN CollectionsJobContractExtracts
					ON CollectionsJobContractExtracts.ContractId = PTPContracts.ContractId
				INNER JOIN @AccessibleLegalEntities AccessibleLegalEntities
					ON AccessibleLegalEntities.LegalEntityId = CollectionsJobContractExtracts.LegalEntityId
			WHERE PaymentPromises.Status = @PaymentPromiseStatusOpen
				AND (DATEDIFF(DD, PaymentPromises.PromiseDate, @ProcessThroughDate) >= 0)
				AND (@CustomerId = 0 OR CollectionWorkLists.CustomerId = @CustomerId)
			ORDER BY PromiseDate ASC, PaymentPromises.Id ASC

	-- FETCH all PTP Contracts
	INSERT INTO #PTPContract
		(
			PaymentPromiseId,
			ContractId
		)
		SELECT DISTINCT
				PTP.PaymentPromiseId,
				PTPContracts.ContractId 
			FROM #OpenPTP PTP
				INNER JOIN PTPContracts ON PTP.ActivityForCollectionWorkListId = PTPContracts.ActivityForCollectionWorkListId
			ORDER BY PTP.PaymentPromiseId ASC, PTPContracts.ContractId ASC

	-- Pick the receipts posted for above contracts between PTP-Creation date and PTP-Promised date
	INSERT INTO #PTPReceipts
		(
			CustomerId,			
			ContractId,
			ReceiptId,
			ReceivedCurrency,
			RemainingBalance,
			ReceivedDate,
			CreatedTime
		)
		SELECT 
				CustomerId,
				ContractId,
				ReceiptId,
				AmountApplied_Currency,
				SUM(RemainingBalance),
				ReceivedDate,
				CreatedTime
			FROM 
			(
				SELECT DISTINCT
						ReceivableDetails.Id AS RDId,
						Receivables.CustomerId,
						Receivables.EntityId AS ContractId,
						Receipts.Id AS ReceiptId,
						ReceiptApplications.AmountApplied_Currency,
						(ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS RemainingBalance,
						Receipts.ReceivedDate,
						Receipts.CreatedTime
					FROM Receipts
						INNER JOIN ReceiptApplications ON Receipts.Id = ReceiptApplications.ReceiptId
						INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
						INNER JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
						INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
							AND Receivables.EntityType = @EntityTypeCT
						INNER JOIN #PTPContract ON Receivables.EntityId = #PTPContract.ContractId
						INNER JOIN #OpenPTP PTP ON #PTPContract.PaymentPromiseId = PTP.PaymentPromiseId
							AND Receivables.CustomerId = PTP.CustomerId					
					WHERE Receipts.Status = @ReceiptStatusPosted
						AND Receipts.CreatedTime > PTP.CreatedTime
						AND (DATEDIFF(DD, Receipts.ReceivedDate, PTP.PromiseDate) >= 0)
						AND PTP.RemainingBalance > 0.00
						AND ReceiptApplicationReceivableDetails.IsActive = 1
						AND (ReceiptApplicationReceivableDetails.AmountApplied_Amount > 0.00 OR ReceiptApplicationReceivableDetails.TaxApplied_Amount > 0.00)
			) AS PTPReceivedReceipts
			GROUP BY CustomerId, ContractId, ReceiptId, ReceivedDate, CreatedTime, AmountApplied_Currency

		-- Update the RemainingBalance if it's already used by PTP earlier.
		UPDATE PPReceipts 
			SET RemainingBalance = #PTPApplicationBalance.RemainingBalance
		FROM #PTPReceipts PPReceipts
			INNER JOIN 
			(
				SELECT #PTPReceipts.RowNumber,
					   (#PTPReceipts.RemainingBalance - SUM(ISNULL(PTPApplications.AmountApplied_Amount, 0.00))) RemainingBalance
				FROM #PTPReceipts
					INNER JOIN PTPApplications ON #PTPReceipts.ContractId = PTPApplications.ContractId
							AND #PTPReceipts.CustomerId = PTPApplications.CustomerId  --- CustomerId not required. join above in the ptpconract.., from collectionworklist..remove..
							AND #PTPReceipts.ReceiptId = PTPApplications.ReceiptId
							AND PTPApplications.IsActive = 1
					GROUP BY #PTPReceipts.RowNumber, #PTPReceipts.RemainingBalance
			) AS #PTPApplicationBalance
			ON PPReceipts.RowNumber = #PTPApplicationBalance.RowNumber

	 DELETE #PTPReceipts WHERE RemainingBalance <= 0.00;

	 DECLARE @PTPCurrentRowNumber BIGINT, @PTPMaxRwoNumber BIGINT;

	 SELECT @PTPCurrentRowNumber = MIN(RowNumber), @PTPMaxRwoNumber = MAX(RowNumber) FROM #OpenPTP

	 -- Iterate for all PTP
	 WHILE @PTPCurrentRowNumber <= @PTPMaxRwoNumber
	 BEGIN
		DECLARE @PaymentPromiseId BIGINT, @PTPCustomerId BIGINT, @PTPRemainingBalance DECIMAL, @PTPPromiseDate DATE, @PTPCreatedTime DATETIMEOFFSET;

		SELECT TOP 1 @PTPCurrentRowNumber = RowNumber, @PaymentPromiseId = PaymentPromiseId, @PTPCustomerId = CustomerId, @PTPRemainingBalance = RemainingBalance, @PTPPromiseDate = PromiseDate, @PTPCreatedTime = CreatedTime
			 FROM #OpenPTP WHERE RowNumber >= @PTPCurrentRowNumber ORDER BY RowNumber ASC;

		DECLARE @ContractCurrentRowNumber BIGINT, @ContractMaxRowNumber BIGINT;

		SELECT @ContractCurrentRowNumber = MIN(RowNumber), @ContractMaxRowNumber = MAX(RowNumber) FROM #PTPContract WHERE PaymentPromiseId = @PaymentPromiseId;
		
		-- Iterate for all the PTP-Contracts
		WHILE (@ContractCurrentRowNumber <= @ContractMaxRowNumber AND @PTPRemainingBalance > 0.00)
		BEGIN
			
			DECLARE @PTPContractId BIGINT;
			SELECT TOP 1 @ContractCurrentRowNumber = RowNumber, @PTPContractId = ContractId FROM #PTPContract WHERE RowNumber >= @ContractCurrentRowNumber AND PaymentPromiseId = @PaymentPromiseId ORDER BY RowNumber ASC;

			DECLARE @ReceiptCurrentRowNumber BIGINT, @ReceiptMaxRowNumber BIGINT;

			SELECT @ReceiptCurrentRowNumber = MIN(RowNumber), @ReceiptMaxRowNumber = MAX(RowNumber) FROM #PTPReceipts WHERE  CustomerId = @PTPCustomerId AND ContractId = @PTPContractId AND  RemainingBalance > 0.00 AND CreatedTime > @PTPCreatedTime AND (DATEDIFF(DD, ReceivedDate, @PTPPromiseDate) >= 0); -- initial filter.. which help us for first or last..

			-- Iterate for all the Contract-Receipts
			WHILE (@ReceiptCurrentRowNumber <= @ReceiptMaxRowNumber AND @PTPRemainingBalance > 0.00)
			BEGIN
				DECLARE @ReceiptId BIGINT, @ReceiptCustomerId BIGINT, @ReceiptContractId BIGINT,  @ReceiptReceivedCurrency NVARCHAR(3),  @ReceiptRemainingBalance DECIMAL(16,2);

				SELECT TOP 1 @ReceiptCurrentRowNumber = RowNumber, @ReceiptId = ReceiptId, @ReceiptCustomerId = CustomerId, @ReceiptContractId = ContractId, @ReceiptReceivedCurrency =  ReceivedCurrency, @ReceiptRemainingBalance = RemainingBalance FROM #PTPReceipts WHERE RowNumber >= @ReceiptCurrentRowNumber AND CustomerId = @PTPCustomerId AND ContractId = @PTPContractId  AND RemainingBalance > 0.00 AND CreatedTime > @PTPCreatedTime AND (DATEDIFF(DD, ReceivedDate, @PTPPromiseDate) >= 0) ORDER BY RowNumber ASC;

				-- If we have found a receipt whose amount can be used, update Remaining balance and PTPApplications
				IF (@ReceiptId IS NOT NULL)
				BEGIN

					DECLARE @ContractAppliedAmount DECIMAL(16,2);

					SET @ContractAppliedAmount = CASE WHEN @ReceiptRemainingBalance <= @PTPRemainingBalance  THEN @ReceiptRemainingBalance ELSE @PTPRemainingBalance END;

					SET @PTPRemainingBalance = @PTPRemainingBalance - @ContractAppliedAmount;   -- Firt loop Variable/global, used to update back below at the end of the first loop.
					SET @ReceiptRemainingBalance = @ReceiptRemainingBalance - @ContractAppliedAmount;
					
					UPDATE #PTPReceipts SET RemainingBalance = @ReceiptRemainingBalance WHERE RowNumber = @ReceiptCurrentRowNumber;

					INSERT INTO #PTPApplicationData (PaymentPromiseId, CustomerId, ContractId, ReceiptId, AmountApplied_Amount, AmountApplied_Currency)
						SELECT @PaymentPromiseId, @ReceiptCustomerId, @ReceiptContractId, @ReceiptId, @ContractAppliedAmount, @ReceiptReceivedCurrency

				END; -- IF condition

				SET @ReceiptCurrentRowNumber = @ReceiptCurrentRowNumber + 1;
			END; -- Receipt Iteration

			SET @ContractCurrentRowNumber = @ContractCurrentRowNumber + 1;
		END; -- Contract Iteration

		UPDATE #OpenPTP SET RemainingBalance = @PTPRemainingBalance WHERE RowNumber = @PTPCurrentRowNumber;

		SET @PTPCurrentRowNumber = @PTPCurrentRowNumber + 1;
	 END; -- PTP Iteration


	 -- Update to the actual tables over here..
	 UPDATE PaymentPromises SET Status = CASE WHEN #OpenPTP.RemainingBalance > 0.00 THEN @PaymentPromiseStatusBroken ELSE @PaymentPromiseStatusKept END,
				UpdatedById = @UserId,
				UpdatedTime = @ServerTimeStamp
			FROM PaymentPromises
					INNER JOIN #OpenPTP ON PaymentPromises.Id = #OpenPTP.PaymentPromiseId


	INSERT INTO PTPApplications (PaymentPromiseId, CustomerId, ContractId, ReceiptId, AmountApplied_Amount, AmountApplied_Currency, IsActive, CreatedById, CreatedTime)
		SELECT PaymentPromiseId, CustomerId, ContractId, ReceiptId, AmountApplied_Amount, AmountApplied_Currency, 1, @UserId, @ServerTimeStamp
			FROM #PTPApplicationData


	DROP TABLE #OpenPTP;
	DROP TABLE #PTPContract;
	DROP TABLE #PTPReceipts;
	DROP TABLE #PTPApplicationData;


END

GO
