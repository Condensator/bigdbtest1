SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTimesLateCounter_Dev]
(
	@ContractId BIGINT
	,@UpdateThroughDate DATETIME
	,@CustomerId BIGINT
)
AS

BEGIN

	--DECLARE
	-- @ContractId BIGINT = 777917
	--,@UpdateThroughDate DATETIME = GETDATE()
	--,@CustomerId BIGINT = 0
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

SELECT * INTO #AgeInDays FROM
(
	SELECT
		 ReceivableInvoiceDetails.EntityID ContractId
		,DATEDIFF(DD,Dateadd(day,LegalEntities.ThresholdDays,ReceivableInvoices.DueDate ),@UpdateThroughDate) AS AgeInDays
	FROM
	ReceivableInvoices
	INNER JOIN ReceivableInvoiceDetails
		ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
		AND ReceivableInvoiceDetails.EntityID = @ContractId
		AND (@CustomerId = 0 OR ReceivableInvoices.CustomerId  = @CustomerId)
		AND ReceivableInvoiceDetails.EntityType = 'CT'
		AND ReceivableInvoices.IsActive = 1
		AND ReceivableInvoices.DueDate <= @UpdateThroughDate
		AND (ReceivableInvoiceDetails.Balance_Amount > 0 OR ReceivableInvoiceDetails.TaxBalance_Amount > 0)
	INNER JOIN ReceivableDetails AS RD ON ReceivableInvoiceDetails.ReceivableDetailId = RD.Id AND RD.IsActive = 1
	INNER JOIN Receivables R ON RD.ReceivableId = R.Id AND R.IsActive = 1
		AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'))
	INNER JOIN Receivablecategories
		On Receivablecategories.id=ReceivableInvoices.ReceivablecategoryId
		AND (ReceivableInvoices.IsDummy=0 OR (ReceivableInvoices.IsDummy=1 AND Receivablecategories.Name NOT IN ('Payoff','AssetSale','Paydown')))
	INNER JOIN LegalEntities
		ON LegalEntities.Id = ReceivableInvoices.LegalEntityId
	GROUP BY
	 ReceivableInvoiceDetails.EntityID
	,ReceivableInvoices.DueDate
	,LegalEntities.ThresholdDays
) AllOpenInvoices
WHERE AllOpenInvoices.AgeInDays > 0

SELECT
	ContractId
	,SUM(CASE WHEN AgeInDays > 0 And AgeInDays <= 30 THEN 1 ELSE 0 END ) AS OneToThirtyCount
	,SUM(CASE WHEN AgeInDays > 30 And AgeInDays <= 60 THEN 1 ELSE 0 END ) AS ThirtyPlusDaysCount
	,SUM(CASE WHEN AgeInDays > 60 And AgeInDays <= 90 THEN 1 ELSE 0 END ) AS SixtyPlusDaysCount
	,SUM(CASE WHEN AgeInDays > 90 And AgeInDays <= 120 THEN 1 ELSE 0 END ) AS NinetyPlusDaysCount
	,SUM(CASE WHEN AgeInDays > 120 THEN 1 ELSE 0 END ) AS OnehunderedTwentyPlusDaysCount
INTO #InvoiceBuckets
FROM #AgeInDays
GROUP BY
	#AgeInDays.ContractId

SELECT
	ISNULL(IB.OneToThirtyCount,0) as OneToThirtyDaysLate,
	ISNULL(IB.ThirtyPlusDaysCount,0) as ThirtyPlusDaysLate,
	ISNULL(IB.SixtyPlusDaysCount,0) as SixtyPlusDaysLate,
	ISNULL (IB.NinetyPlusDaysCount,0) as NinetyPlusDaysLate,
	ISNULL (IB.OnehunderedTwentyPlusDaysCount,0) as OneHundredTwentyPlusDaysLate
FROM #InvoiceBuckets IB
WHERE IB.contractId = @ContractId

SELECT
	ISNULL(ContractDetails.TotalOneToThirtyDaysLate,0) as TotalOneToThirtyDaysLate ,
	ISNULL(ContractDetails.TotalThirtyPlusDaysLate,0) as TotalThirtyPlusDaysLate ,
	ISNULL(ContractDetails.TotalSixtyPlusDaysLate,0) as TotalSixtyPlusDaysLate ,
	ISNULL(ContractDetails.TotalNinetyPlusDaysLate,0) as TotalNinetyPlusDaysLate,
	ISNULL(ContractDetails.TotalOneHundredTwentyPlusDaysLate,0) as TotalOneHundredTwentyPlusDaysLate
FROM ContractCollectionDetails ContractDetails
WHERE ContractDetails.ContractId= @ContractId

DROP TABLE #AgeInDays
DROP TABLE #InvoiceBuckets

END


GO
