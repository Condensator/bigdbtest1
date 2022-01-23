SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetInvoiceAgingSummary]
(
	@CollectionWorkListId BIGINT,
	@EntityTypeCT NVARCHAR(2)
)
AS 
BEGIN 

	SELECT
			ReceivableInvoices.Id AS ReceivableInvoiceId
			,ReceivableInvoiceDetails.Balance_Currency AS Currency
			,Sum(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) DueAmount
			,ReceivableInvoices.DaysLateCount AS DaysPastDue
		INTO #DeliquentReceivables
		FROM 
			CollectionWorkLists
			INNER JOIN CollectionWorkListContractDetails ON CollectionWorkLists.Id = CollectionWorkListContractDetails.CollectionWorkListId
			INNER JOIN ReceivableInvoiceDetails ON CollectionWorkListContractDetails.ContractId = ReceivableInvoiceDetails.EntityId 
				AND ReceivableInvoiceDetails.EntityType = @EntityTypeCT
				AND ReceivableInvoiceDetails.IsActive = 1 
			INNER JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id 
				AND ReceivableInvoices.CustomerId = CollectionWorkLists.CustomerId
				AND ReceivableInvoices.IsActive = 1				
			INNER JOIN ReceivableInvoiceDeliquencyDetails ON ReceivableInvoices.Id = ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId	
		WHERE 
			CollectionWorkLists.Id = @CollectionWorkListId
			AND CollectionWorkListContractDetails.IsWorkCompleted = 0
			AND 
			(
				-- To fetch records belonging to worklist remit to
				(CollectionWorkLists.RemitToId IS NOT NULL AND CollectionWorkLists.RemitToId = ReceivableInvoices.RemitToId AND ReceivableInvoices.IsPrivateLabel = 1)
				OR (CollectionWorkLists.RemitToId IS NULL AND ReceivableInvoices.IsPrivateLabel = 0)
			) 
		GROUP BY ReceivableInvoices.Id, ReceivableInvoiceDetails.Balance_Currency, ReceivableInvoices.DaysLateCount
				

	SELECT 
			ReceivableInvoiceId
			,(CASE WHEN DaysPastDue BETWEEN 1 AND 30 THEN 1 ELSE 0 END) AS IsOneToThirtyDue
			,(CASE WHEN DaysPastDue BETWEEN 31 AND 60 THEN 1 ELSE 0 END) AS IsThirtyOneToSixtyDue
			,(CASE WHEN DaysPastDue BETWEEN 61 AND 90 THEN 1 ELSE 0 END) AS IsSixtyOneToNintyDue
			,(CASE WHEN DaysPastDue BETWEEN 91 AND 120 THEN 1 ELSE 0 END) AS IsNintyOneToOneHundredTwentyDue
			,(CASE WHEN DaysPastDue > 120 THEN 1 ELSE 0 END) AS IsOneHundredTwentyPlusDue
		INTO #ReceivableBucketing
		FROM #DeliquentReceivables


	SELECT 
			SUM(IsOneToThirtyDue) AS OneToThirtyDueCount,  -- how many ReceivableInvoices are due in this bucket, will be used for label, beside the USD amount in graph
			SUM(IsThirtyOneToSixtyDue) AS ThirtyOneToSixtyDueCount,
			SUM(IsSixtyOneToNintyDue) AS SixtyOneToNintyDueCount,
			SUM(IsNintyOneToOneHundredTwentyDue) AS NintyOneToThirtyDueCount,
			SUM(IsOneHundredTwentyPlusDue) AS OneHundredTwentyPlusPlusDueCount,

			SUM(IsOneToThirtyDue * DueAmount) AS OneToThirtyDueAmount,  -- Total due as of today for this bucket.
			SUM(IsThirtyOneToSixtyDue * DueAmount) AS ThirtyOneToSixtyDueAmount,
			SUM(IsSixtyOneToNintyDue * DueAmount) AS SixtyOneToNintyDueAmount,
			SUM(IsNintyOneToOneHundredTwentyDue * DueAmount) AS NintyOneToThirtyDueAmount,
			SUM(IsOneHundredTwentyPlusDue * DueAmount) AS OneHundredTwentyPlusDueAmount
		INTO #BucketSummary
		FROM #DeliquentReceivables
			INNER JOIN #ReceivableBucketing ON #DeliquentReceivables.ReceivableInvoiceId = #ReceivableBucketing.ReceivableInvoiceId

	DECLARE @Currency NVARCHAR(3); -- Currency can be passed as input also..
	SELECT TOP 1 @Currency = Currency FROM #DeliquentReceivables;
	
	;WITH SummaryData (Id, Bucket, TimesLate, Amount_Amount, Amount_Currency) AS
	(
		SELECT 1, '1-30', (OneToThirtyDueCount + ThirtyOneToSixtyDueCount + SixtyOneToNintyDueCount + NintyOneToThirtyDueCount + OneHundredTwentyPlusPlusDueCount), OneToThirtyDueAmount, @Currency FROM #BucketSummary
		UNION 
		SELECT 2, '31-60', (ThirtyOneToSixtyDueCount + SixtyOneToNintyDueCount + NintyOneToThirtyDueCount + OneHundredTwentyPlusPlusDueCount), ThirtyOneToSixtyDueAmount, @Currency FROM #BucketSummary
		UNION
		SELECT 3, '61-90', (SixtyOneToNintyDueCount + NintyOneToThirtyDueCount + OneHundredTwentyPlusPlusDueCount), SixtyOneToNintyDueAmount, @Currency FROM #BucketSummary
		UNION 
		SELECT 4, '91-120', (NintyOneToThirtyDueCount + OneHundredTwentyPlusPlusDueCount), NintyOneToThirtyDueAmount, @Currency FROM #BucketSummary
		UNION
		SELECT 5, '120+', OneHundredTwentyPlusPlusDueCount, OneHundredTwentyPlusDueAmount, @Currency FROM #BucketSummary
	)
	SELECT * FROM SummaryData ORDER BY Id ASC;  -- Id is added just for ordering purpose..


	DROP TABLE #DeliquentReceivables;
	DROP TABLE #BucketSummary;

END

GO
