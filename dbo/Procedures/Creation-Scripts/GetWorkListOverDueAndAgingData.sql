SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetWorkListOverDueAndAgingData]
(
	@CollectionWorkListId			BIGINT,
	@ReceivableEntityTypeCT			NVARCHAR(2),
	@ReceiptEntityTypeLease			NVARCHAR(20),
	@ReceiptEntityTypeLoan			NVARCHAR(20),
	@ReceiptClassificationNonCash	NVARCHAR(23),
	@ReceiptClassificationNonAccrualNonDSLNonCash NVARCHAR(23),
	@PaymentPromiseStatusOpen		NVARCHAR(6),
	@ReceiptStatusPending			NVARCHAR(15),
	@ReceiptStatusSubmitted			NVARCHAR(15),
	@ReceiptStatusReadyForPosting	NVARCHAR(15),
	@ReceiptStatusPosted			NVARCHAR(15)
)
AS 
BEGIN 

	SELECT DISTINCT
			ReceivableInvoices.Id AS ReceivableInvoiceId
			,ReceivableInvoiceDetails.Id AS ReceivableInvoiceDetailId
			,ReceivableInvoiceDetails.Balance_Currency AS Currency
			,(CASE WHEN ReceivableTypes.Name IN ('CPIBaseRental', 'CPIOverage', 'CapitalLeaseRental', 'InterimRental', 'LeaseFloatRateAdj', 'LeveragedLeaseRental', 'LoanPrincipal', 'OperatingLeaseRental') THEN 1 ELSE 0 END) AS IsRental
			,(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) DueAmount 
			,ReceivableInvoices.DaysLateCount AS DaysPastDue
		INTO #DeliquentReceivableInvoices
		FROM 
			CollectionWorkLists
			INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
			INNER JOIN ReceivableInvoiceDetails ON CollectionWorkListContractDetails.ContractId = ReceivableInvoiceDetails.EntityId 
				AND ReceivableInvoiceDetails.EntityType = @ReceivableEntityTypeCT
				AND ReceivableInvoiceDetails.IsActive = 1 
			INNER JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id 
				AND ReceivableInvoices.CustomerId = CollectionWorkLists.CustomerId
				AND ReceivableInvoices.CurrencyId = CollectionWorkLists.CurrencyId
				AND ReceivableInvoices.IsActive = 1				
			INNER JOIN ReceivableInvoiceDeliquencyDetails ON ReceivableInvoices.Id = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId	
			INNER JOIN Receivables ON Receivables.Id = ReceivableInvoiceDetails.ReceivableId
			INNER JOIN ReceivableCodes ON ReceivableCodes.Id = Receivables.ReceivableCodeId
			INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
		WHERE 
			CollectionWorkLists.Id = @CollectionWorkListId
			AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			AND 
			(
				-- To fetch records belonging to worklist remit to
				(CollectionWorkLists.RemitToId IS NOT NULL AND CollectionWorkLists.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
				OR (CollectionWorkLists.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
			) 

	SELECT
			ReceivableInvoiceId
			,Currency
			,SUM(CASE WHEN IsRental = 1 THEN DueAmount ELSE 0 END) AS RentalDueAmount
			,SUM(CASE WHEN IsRental = 0 THEN DueAmount ELSE 0 END) AS NonRentalDueAmount
			,SUM(DueAmount) DueAmount 
			,DaysPastDue
		INTO #DeliquentReceivables
		FROM 
			#DeliquentReceivableInvoices
		GROUP BY ReceivableInvoiceId, Currency, DaysPastDue


	DECLARE @Currency NVARCHAR(3); -- Currency can be passed as input also..
	DECLARE @MaxDaysPastDue INT;
	DECLARE @TotalRentalDueAmount DECIMAL(16, 2);
	DECLARE @TotalNonRentalDueAmount DECIMAL(16, 2);
	DECLARE @TotalDueAmount DECIMAL(16, 2);	
	DECLARE @OpenPTPAmount DECIMAL(16, 2);
	DECLARE @TotalPendingAmount DECIMAL(16, 2);
	DECLARE @TotalUnappliedAmount DECIMAL(16, 2);
	
	SELECT TOP 1 @Currency = Currency FROM #DeliquentReceivables;

	SELECT @MaxDaysPastDue = MAX(ISNULL(DaysPastDue, 0))
			FROM #DeliquentReceivableInvoices
			WHERE DueAmount > 0.00

	SELECT 			
			@TotalRentalDueAmount = SUM(RentalDueAmount),
			@TotalNonRentalDueAmount = SUM(NonRentalDueAmount),
			@TotalDueAmount = SUM(DueAmount)
		FROM #DeliquentReceivables


	SELECT 
			@OpenPTPAmount = SUM(PaymentPromises.Amount_Amount)
		FROM 
			CollectionWorkLists
			INNER JOIN ActivityForCollectionWorkLists ON CollectionWorkLists.Id = ActivityForCollectionWorkLists.CollectionWorkListId
			INNER JOIN PaymentPromises ON ActivityForCollectionWorkLists.Id = PaymentPromises.ActivityId
		WHERE PaymentPromises.Status = @PaymentPromiseStatusOpen
			AND CollectionWorkLists.Id = @CollectionWorkListId

			
	CREATE TABLE #EligibleReceipts
	(
		ReceiptId BIGINT NOT NULL,
		Status NVARCHAR(30),
		Balance_Amount DECIMAL(16, 2) NOT NULL,
		AmountApplied_Amount DECIMAL(16, 2) NOT NULL,
		TaxApplied_Amount DECIMAL(16, 2) NOT NULL		
	)

	INSERT INTO #EligibleReceipts
		SELECT
			Receipts.Id,
			Receipts.Status,
			Receipts.Balance_Amount,
			SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount),
			SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount)
		FROM Receipts
			INNER JOIN ReceiptApplications 
				ON Receipts.Id = ReceiptApplications.ReceiptId
			INNER JOIN ReceiptApplicationReceivableDetails 
				ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
				AND ReceiptApplicationReceivableDetails.IsActive = 1
			INNER JOIN ReceivableDetails
				ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
				AND ReceivableDetails.IsActive = 1
			INNER JOIN Receivables 
				ON ReceivableDetails.ReceivableId = Receivables.Id
				AND Receivables.EntityType = @ReceivableEntityTypeCT
				AND Receivables.IsActive = 1
			INNER JOIN CollectionWorkLists ON Receivables.CustomerId = CollectionWorkLists.CustomerId
				AND Receipts.CurrencyId = CollectionWorkLists.CurrencyId
			INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
				AND Receivables.EntityId = CollectionWorkListContractDetails.ContractId
		WHERE  
			CollectionWorkLists.Id = @CollectionWorkListId
			AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
			AND Receipts.Status IN (@ReceiptStatusPending, @ReceiptStatusReadyForPosting, @ReceiptStatusSubmitted)	
			AND 
			(
				-- To fetch records belonging to worklist remit to
				(CollectionWorkLists.RemitToId IS NOT NULL AND CollectionWorkLists.RemitToId = Receivables.RemitToId AND Receivables.IsPrivateLabel = 1)
				OR (CollectionWorkLists.RemitToId IS NULL AND Receivables.IsPrivateLabel = 0)
			) 
		GROUP BY Receipts.Id, Receipts.Status, Receipts.Balance_Amount;


	INSERT INTO #EligibleReceipts
		SELECT DISTINCT
			Receipts.Id, 
			Receipts.Status,
			Receipts.Balance_Amount,
			Receipts.ReceiptAmount_Amount,
			0.00 AS TaxApplied_Amount
		FROM CollectionWorkLists 
			INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
			INNER JOIN Receipts ON CollectionWorkListContractDetails.ContractId = Receipts.ContractId
				AND CollectionWorkLists.CurrencyId = Receipts.CurrencyId
				AND Receipts.EntityType IN (@ReceiptEntityTypeLease, @ReceiptEntityTypeLoan)
			LEFT JOIN ReceiptApplications 
				ON Receipts.Id = ReceiptApplications.ReceiptId
			LEFT JOIN ReceiptApplicationReceivableDetails 
				ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
				AND ReceiptApplicationReceivableDetails.IsActive = 1
		WHERE 
			ReceiptApplicationReceivableDetails.ReceiptApplicationId is NULL
			AND CollectionWorkLists.Id = @CollectionWorkListId
			AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
			AND Receipts.Status IN (@ReceiptStatusPending, @ReceiptStatusReadyForPosting, @ReceiptStatusSubmitted);			

	SELECT
			@TotalPendingAmount = SUM(AmountApplied_Amount + TaxApplied_Amount)
		FROM #EligibleReceipts
		WHERE Status IN (@ReceiptStatusPending, @ReceiptStatusReadyForPosting, @ReceiptStatusSubmitted);

		
	CREATE TABLE #UnAppliedReceipts
	(
		ReceiptId BIGINT,
		Balance_Amount DECIMAL(16, 2)
	);

	--Customer level unapplied
	INSERT INTO #UnAppliedReceipts
		SELECT  DISTINCT
			Receipts.Id AS ReceiptId,
			Receipts.Balance_Amount
		FROM Receipts
			INNER JOIN CollectionWorkLists ON Receipts.CustomerId = CollectionWorkLists.CustomerId
				AND Receipts.CurrencyId = CollectionWorkLists.CurrencyId
		WHERE CollectionWorkLists.Id = @CollectionWorkListId
			AND Receipts.Balance_Amount > 0.00
			AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
			AND Receipts.Status = @ReceiptStatusPosted; 

	--Contract level unapplied
	INSERT INTO #UnAppliedReceipts
		SELECT DISTINCT
				Receipts.Id AS ReceiptId,
				Receipts.Balance_Amount
			FROM CollectionWorkLists 
				INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
				INNER JOIN Receipts ON CollectionWorkListContractDetails.ContractId = Receipts.ContractId
					AND Receipts.CurrencyId = CollectionWorkLists.CurrencyId
			WHERE 
				CollectionWorkLists.Id = @CollectionWorkListId
				AND CollectionWorkListContractDetails.IsWorkCompleted = 0
				AND Receipts.Balance_Amount > 0.00
				AND Receipts.ReceiptClassification NOT IN (@ReceiptClassificationNonCash, @ReceiptClassificationNonAccrualNonDSLNonCash)
				AND Receipts.Status = @ReceiptStatusPosted;

	SELECT
			@TotalUnappliedAmount = SUM(Balance_Amount)
		FROM #UnAppliedReceipts


	SELECT ISNULL(@MaxDaysPastDue, 0) AS DaysPastDue
			,ISNULL(@TotalRentalDueAmount, 0.00) AS RentalDueAmount_Amount
			,@Currency AS RentalDueAmount_Currency
			,ISNULL(@TotalNonRentalDueAmount, 0.00) AS NonRentalDueAmount_Amount
			,@Currency AS NonRentalDueAmount_Currency
			,ISNULL(@TotalDueAmount, 0.00) AS PastDueAmount_Amount
			,@Currency AS PastDueAmount_Currency
			,ISNULL(@OpenPTPAmount, 0.00) AS OpenPTPAmount_Amount
			,@Currency AS OpenPTPAmount_Currency
			,ISNULL(@TotalPendingAmount, 0.00) AS PendingAmount_Amount
			,@Currency AS PendingAmount_Currency
			,ISNULL(@TotalUnappliedAmount, 0.00) AS UnappliedAmount_Amount
			,@Currency AS UnappliedAmount_Currency


	DROP TABLE #DeliquentReceivables;
	DROP TABLE #EligibleReceipts;
	DROP TABLE #UnAppliedReceipts;

END

GO
