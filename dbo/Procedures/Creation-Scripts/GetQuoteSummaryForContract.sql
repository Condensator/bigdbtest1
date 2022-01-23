SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetQuoteSummaryForContract]
(
@ContractSequenceNumber nvarchar(80),
@FullPayOff NVARCHAR(20),
@PartialPayOff NVARCHAR(20),
@AssetSale NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON
Declare @ContractId as bigint;
SET @ContractId = (Select Id from Contracts Where SequenceNumber = @ContractSequenceNumber)
SELECT
ROW_NUMBER() OVER (PARTITION BY TerminatedAssets.AssetId ORDER BY TerminatedAssets.Id DESC) AS RowNumber
,TerminatedAssets.Id AS  LeaseAssetId
,TerminatedAssets.AssetId AS  AssetId
INTO #InActiveLeasedAsset
FROM
LeaseFinances LF
INNER JOIN Contracts
ON LF.ContractId = Contracts.Id
AND LF.IsCurrent = 1
AND Contracts.Id =  @ContractId
INNER JOIN LeaseAssets LA
ON LF.Id = LA.LeaseFinanceId
AND (LA.IsActive = 0
AND LA.TerminationDate IS NOT NULL)
INNER JOIN LeaseAssets TerminatedAssets
on  LA.AssetId = TerminatedAssets.AssetId
AND TerminatedAssets.IsActive = 1
INNER JOIN LeaseFinances PreviousLeaseFinances on
TerminatedAssets.LeaseFinanceId = PreviousLeaseFinances.Id
AND PreviousLeaseFinances.ContractId = Contracts.Id
UNION
SELECT
NULL AS  RowNumber
,NULL AS  LeaseAssetId
,CA.AssetId AS  AssetId
FROM
LoanFinances LF
INNER JOIN Contracts
ON LF.ContractId = Contracts.Id
AND LF.IsCurrent = 1
AND Contracts.Id =  @ContractId
INNER JOIN CollateralAssets CA
ON LF.Id = CA.LoanFinanceId
AND (CA.IsActive = 0
AND CA.TerminationDate IS NOT NULL)
INNER JOIN Assets
ON Assets.Id = CA.AssetId
AND Assets.Status = 'Sold'
;WITH
CTE_PayoffQuotes
AS
(
SELECT
PayoffAssets.PayoffId
,SUM(ISNULL(PayoffAssets.PayoffAmount_Amount,0.00)) [PayoffAmount_Amount]
,SUM(ISNULL(PayoffAssets.BuyoutAmount_Amount,0.00)) [BuyoutAmount_Amount]
FROM
#InActiveLeasedAsset InActiveLeasedAsset
INNER JOIN PayoffAssets
ON InActiveLeasedAsset.LeaseAssetId = PayoffAssets.LeaseAssetId
AND PayoffAssets.IsActive = 1
GROUP BY
PayoffAssets.PayoffId
),
CTE_AssetSaleDetails
AS
(
SELECT
ASD.AssetSaleId
,SUM(ISNULL(ASD.FairMarketValue_Amount,0.00)) AssetSaleAmount
FROM
#InActiveLeasedAsset InActiveLeasedAsset
INNER JOIN AssetSaleDetails AS ASD
ON InActiveLeasedAsset.AssetId = ASD.AssetId
AND InActiveLeasedAsset.RowNumber = 1
AND ASD.IsActive = 1
GROUP BY
ASD.AssetSaleId
)
SELECT
Payoffs.QuoteNumber QuoteNumber
,PayOffs.QuoteName QuoteName
,Payoffs.Id EntityId
,'Payoff' EntityName
,CASE WHEN Payoffs.FullPayoff =1  THEN @FullPayOff ELSE @PartialPayOff END QuoteType
,Payoffs.Status QuoteStatus
,PayOffs.PostDate
,Payoffs.DueDate
,PayoffQuotes.PayoffAmount_Amount AS [PayoffAmount]
,PayoffQuotes.BuyoutAmount_Amount AS [BuyoutAmount]
,0.00 As [InterestPaydownAmount]
,0.00 As [PrincipalPaydownAmount]
,Payoffs.PayoffAmount_Currency Currency
,STUFF((SELECT
DISTINCT ',' + ReceivableInvoices.Number
FROM
CTE_PayoffQuotes InvoicedPayoffs
INNER JOIN PayoffInvoices
ON PayoffInvoices.PayoffId = InvoicedPayoffs.PayoffId
and PayoffQuotes.PayoffId = InvoicedPayoffs.PayoffId
INNER JOIN ReceivableInvoices
ON ReceivableInvoices.id = PayoffInvoices.InvoiceId
AND ReceivableInvoices.IsDummy = 0
GROUP BY
InvoicedPayoffs.PayoffId
,ReceivableInvoices.Number
FOR XML PATH('')
), 1, 1, '')	InvoiceNumber
,'Edit' TransactionName
FROM
CTE_PayoffQuotes PayoffQuotes
INNER JOIN Payoffs
on  PayoffQuotes.PayoffId = Payoffs.Id
and Payoffs.Status = 'Activated'
UNION
SELECT
LoanPaydowns.QuoteNumber QuoteNumber
,LoanPaydowns.QuoteName QuoteName
,LoanPaydowns.Id EntityId
,'LoanPaydown' EntityName
,LoanPaydowns.PaydownReason AS QuoteType
,LoanPaydowns.Status QuoteStatus
,LoanPaydowns.PostDate
,LoanPaydowns.DueDate
,0.00 AS [PayoffAmount]
,0.00 AS [BuyoutAmount]
,LoanPaydowns.InterestPaydown_Amount AS [InterestPaydownAmount]
,LoanPaydowns.PrincipalPaydown_Amount AS [PrincipalPaydownAmount]
,LoanPaydowns.PrincipalPaydown_Currency Currency
,COALESCE(ReceivableInvoices.Number, ' ') [InvoiceNumber]
,'Edit' TransactionName
FROM
LoanFinances
INNER JOIN Contracts
ON  LoanFinances.ContractId = Contracts.Id
AND Contracts.Id =  @ContractId
INNER JOIN LoanPaydowns
ON LoanPaydowns.LoanFinanceId = LoanFinances.Id
AND LoanPaydowns.Status = 'Active'
LEFT JOIN ReceivableInvoices
ON  LoanPaydowns.InvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsDummy = 0
UNION
SELECT
AssetSales.TransactionNumber QuoteNumber
,AssetSales.TransactionNumber QuoteName
,AssetSales.Id EntityId
,'AssetSale' EntityName
,@AssetSale  QuoteType
,AssetSales.Status QuoteStatus
,AssetSales.PostDate
,AssetSales.DueDate
,0.00 AS [PayoffAmount]
,CTE_AssetSaleDetails.AssetSaleAmount AS [BuyoutAmount]
,0.00 AS [InterestPaydownAmount]
,0.00 AS [PrincipalPaydownAmount]
,AssetSales.Amount_Currency Currency
,STUFF((SELECT
DISTINCT ',' + ReceivableInvoices.Number
FROM
Receivables
INNER JOIN ReceivableDetails
ON ReceivableId = Receivables.id
AND Receivables.EntityId = @ContractId
AND Receivables.EntityType = 'CT'
INNER JOIN ReceivableInvoiceDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.id
INNER JOIN ReceivableInvoices
ON  ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsDummy = 0
INNER JOIN AssetSaleReceivables
ON Receivables.SourceId = AssetSaleReceivables.Id
AND Receivables.SourceTable = 'AssetSaleReceivable'
GROUP BY
AssetSaleReceivables.AssetSaleId
,ReceivableInvoices.Number
FOR XML PATH('')
), 1, 1, '')	InvoiceNumber
,'Edit' TransactionName
FROM
CTE_AssetSaleDetails
INNER JOIN AssetSales
ON CTE_AssetSaleDetails.AssetSaleId = AssetSales.Id
AND AssetSales.Status = 'Completed'
DROP TABLE #InActiveLeasedAsset
END

GO
