SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CustomerBillingAndAgingReport]
@LegalEntityId BIGINT,
@CustomerId BIGINT,
@AsOfDate AS Date,
@IsAllLENeeded BIGINT
AS
BEGIN
--declare @LegalEntityId bigint = 1
--declare @CustomerId bigint= 71040
--declare @AsOfDate Date = '2016-09-15'
--declare @IsAllLENeeded BIGINT = 1
SET NOCOUNT ON
DECLARE
@R_0_10 BIGINT = 0,
@R_10_30 BIGINT = 0,
@R_30_60 BIGINT = 0,
@R_60_ABOVE BIGINT = 0,
@R_NULL BIGINT = 0,
@NR_0_10 BIGINT = 0,
@NR_10_30 BIGINT = 0,
@NR_30_60 BIGINT = 0,
@NR_60_ABOVE BIGINT = 0,
@NR_NULL BIGINT = 0

SELECT 
	RI.Id AS 'InvoiceId',
	MAX(R.ReceivedDate) AS 'Received Date',
	SUM(RID.InvoiceAmount_Amount) AS 'Amount Billed',
	SUM(RID.InvoiceTaxAmount_Amount) AS 'Tax Billed' ,
	SUM(RID.InvoiceAmount_Amount) +SUM(RID.InvoiceTaxAmount_Amount) AS 'Total Billed',
	SUM(RID.Balance_Amount) +SUM(RID.TaxBalance_Amount) AS 'Balance',
	SUM(CASE WHEN R.ReceiptClassification IN ('NonCash','NonAccrualNonDSLNonCash') THEN (RARD.AmountApplied_Amount + RARD.TaxApplied_Amount) END) AS 'Adjustments',
	SUM(CASE WHEN (R.ReceiptClassification NOT IN ('NonCash','NonAccrualNonDSLNonCash') AND R.Status IN ('Completed', 'Posted')) THEN (RARD.AmountApplied_Amount + RARD.TaxApplied_Amount) END) AS 'Paid To Date',
	RT.Name AS 'Receivable Type',
	ReceivableCategories.Id AS 'ReceivableCategoryId',
    MAX(CASE WHEN Status IN ('Completed', 'Posted') THEN 1 ELSE 0 END) AS IsPostedOrCompleted
INTO #ReceivableInvoiceData
FROM ReceivableInvoices RI 
	INNER JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailID = RD.Id
	INNER JOIN Receivables Rec ON Rec.Id = RD.ReceivableId 
	INNER JOIN ReceivableCodes RC ON Rec.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN ReceivableCategories ON RID.ReceivableCategoryId = ReceivableCategories.Id
	LEFT JOIN ReceiptApplicationReceivableDetails RARD ON RID.ReceivableDetailId = RARD.ReceivableDetailId AND RARD.IsActive =1
	LEFT JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id
	LEFT JOIN Receipts R ON RA.ReceiptId = R.Id AND R.Status <> 'Reversed'
WHERE RI.CustomerId = @CustomerId AND (@IsAllLENeeded = 1 OR RI.LegalEntityId = @LegalEntityId) 
	AND RI.IsActive =1 AND RI.DueDate < = @AsOfDate AND Rec.IsDummy = 0 AND RI.Balance_Amount != 0
GROUP BY RI.Id, ReceivableCategories.Id, RT.Name

SELECT InvoiceTypes.Name AS 'Type', #ReceivableInvoiceData.InvoiceId AS 'InvoiceId',#ReceivableInvoiceData.[Received Date],
	DATEDIFF(DAY,ReceivableInvoices.DueDate, @AsOfDate) AS 'Age',
	#ReceivableInvoiceData.IsPostedOrCompleted,
	ROW_NUMBER() OVER (PARTITION BY #ReceivableInvoiceData.InvoiceId ORDER BY #ReceivableInvoiceData.[Received Date] DESC, ABS(#ReceivableInvoiceData.[Paid To Date]) DESC) AS 'IsMaxRecord',
	#ReceivableInvoiceData.[Paid To Date]
INTO #CountOfRecords
FROM ReceivableInvoices
	JOIN #ReceivableInvoiceData on ReceivableInvoices.Id = #ReceivableInvoiceData.InvoiceId
	JOIN ReceivableCategories on #ReceivableInvoiceData.ReceivableCategoryId = ReceivableCategories.Id
	JOIN InvoiceTypes on ReceivableCategories.InvoiceTypeId = InvoiceTypes.Id
--select  * from #CountOfRecords
	SELECT @R_0_10 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type = 'Rental' AND Age <= 10 AND IsPostedOrCompleted = 1  AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND IsMaxRecord = 1
	SELECT @R_10_30 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type = 'Rental' AND Age > 10 AND IsPostedOrCompleted = 1  AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND Age <= 30 AND IsMaxRecord = 1
	SELECT @R_30_60 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type = 'Rental' AND Age > 30 AND IsPostedOrCompleted = 1  AND [Received Date] IS NOT NULL  AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND Age <= 60 AND IsMaxRecord = 1
	SELECT @R_60_ABOVE = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type = 'Rental' AND Age > 60 AND IsPostedOrCompleted = 1  AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND IsMaxRecord = 1
	SELECT @R_NULL = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type = 'Rental' AND  IsPostedOrCompleted = 0 AND ([Received Date] IS NULL OR [Paid To Date] = 0) AND IsMaxRecord = 1
	SELECT @NR_0_10 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type <> 'Rental' AND IsPostedOrCompleted = 1 AND Age <= 10 AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND IsMaxRecord = 1
	SELECT @NR_10_30 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type <> 'Rental' AND IsPostedOrCompleted = 1 AND Age > 10 AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND Age <= 30 AND IsMaxRecord = 1
	SELECT @NR_30_60 = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type <> 'Rental' AND IsPostedOrCompleted = 1  AND Age > 30 AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND Age <= 60 AND IsMaxRecord = 1
	SELECT @NR_60_ABOVE = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type <> 'Rental'AND IsPostedOrCompleted = 1  AND Age > 60 AND [Received Date] IS NOT NULL AND ([Paid To Date] IS NULL OR [Paid To Date] != 0) AND IsMaxRecord = 1
	SELECT @NR_NULL = count(1) FROM #CountOfRecords WHERE #CountOfRecords.Type <> 'Rental' AND IsPostedOrCompleted = 0 AND ([Received Date] IS NULL OR [Paid To Date] = 0) AND IsMaxRecord = 1
	SELECT  ReceivableInvoices.Number ,
	#ReceivableInvoiceData.[Receivable Type] ,
	ReceivableInvoices.DueDate ,
	#ReceivableInvoiceData.[Amount Billed] ,
	#ReceivableInvoiceData.[Tax Billed] ,
	#ReceivableInvoiceData.[Total Billed] ,
	#ReceivableInvoiceData.Balance ,
	#ReceivableInvoiceData.Adjustments ,
	#ReceivableInvoiceData.[Paid To Date] ,
	DATEDIFF(DAY ,ReceivableInvoices.DueDate ,@AsOfDate) AS 'Age',
	@R_0_10 AS '@R_0_10',
	@R_10_30 AS '@R_10_30',
	@R_30_60 AS '@R_30_60',
	@R_60_ABOVE AS '@R_60_ABOVE',
	@NR_0_10 AS '@NR_0_10',
	@NR_10_30 AS '@NR_10_30',
	@NR_30_60 AS '@NR_30_60',
	@NR_60_ABOVE AS '@NR_60_ABOVE',
	@R_NULL AS '@R_NULL',
	@NR_NULL AS '@NR_NULL'
FROM ReceivableInvoices
	JOIN #ReceivableInvoiceData on ReceivableInvoices.Id = #ReceivableInvoiceData.InvoiceId
ORDER BY receivableinvoices.id

DROP TABLE #ReceivableInvoiceData
DROP TABLE #CountOfRecords
END

GO
