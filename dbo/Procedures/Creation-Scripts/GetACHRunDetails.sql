SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetACHRunDetails]
(
@FromDate AS DATE = NULL,
@ToDate AS DATE = NULL,
@LegalEntityNumber NVARCHAR(100) = NULL
)
AS
BEGIN
DECLARE @FilterCriteria NVARCHAR(250)= NULL
IF (@LegalEntityNumber IS NOT NULL AND LEN(@LegalEntityNumber)>0)
SET @FilterCriteria='LegalEntityNumber:'+@LegalEntityNumber
IF (@FromDate IS NOT NULL AND LEN(@FromDate)>0)
SET @FilterCriteria=@FilterCriteria + ' From Date:'+CONVERT(NVARCHAR(10), @FromDate, 101)
IF (@ToDate IS NOT NULL AND LEN(@ToDate)>0)
SET @FilterCriteria=@FilterCriteria + ' To Date:'+CONVERT(NVARCHAR(10), @ToDate, 101)
;WITH CTE AS
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY EntityId ORDER BY EntityId) AS rn
FROM ACHRunDetails
)
SELECT * into #DistinctACHRunDetails FROM CTE
WHERE rn = 1
;WITH CustomerDetails
AS
(
Select
Distinct ACHRunDetails.EntityId
,Parties.PartyName
From ACHRunDetails
INNER JOIN ReceiptApplications
ON ACHRunDetails.EntityId = ReceiptApplications.ReceiptId
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
INNER JOIN ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN Parties
ON Receivables.CustomerId = Parties.Id
)
SELECT
@FilterCriteria,
CASE WHEN @FromDate IS NOT NULL THEN @FromDate
ELSE NULL END AS [FromDate],
CASE WHEN @ToDate IS NOT NULL THEN @ToDate
ELSE GETDATE() END AS [ToDate],
CASE WHEN @LegalEntityNumber IS NOT NULL
THEN @LegalEntityNumber ELSE '0' END AS [LegalEntityNumber],
COALESCE(CustomerDetails.PartyName,PartyDetails.PartyName) as [Name],
ACHRunId =ACHRuns.Id,
'Sum of Total Payment'=SUM(Receipts.ReceiptAmount_Amount),
'Total Payment Processed'=COUNT(Receipts.Id)
,Currecy=Receipts.ReceiptAmount_Currency
FROM ACHRuns
INNER JOIN #DistinctACHRunDetails
ON ACHRuns.Id = #DistinctACHRunDetails.ACHRunId
INNER JOIN Receipts
ON #DistinctACHRunDetails.EntityId=Receipts.Id
LEFT JOIN CustomerDetails
ON #DistinctACHRunDetails.EntityId = CustomerDetails.EntityId
LEFT JOIN Parties PartyDetails
ON Receipts.Customerid = PartyDetails.Id
INNER JOIN LegalEntities
ON Receipts.LegalEntityId=LegalEntities.Id
WHERE REceipts.Status!='Inactive'
AND (@FromDate IS NULL OR CAST(Receipts.CreatedTime AS DATE) >= CAST(@FromDate AS DATE))
AND (@ToDate IS NULL OR CAST(Receipts.CreatedTime AS DATE) <= CAST(@ToDate AS DATE))
AND (@LegalEntityNumber IS NULL OR @LegalEntityNumber=LegalEntities.LegalEntityNumber)
AND (ACHRuns.EntityType='Receipt')
GROUP BY  ACHRuns.Id,CustomerDetails.PartyName,PartyDetails.PartyName,Receipts.ReceiptAmount_Currency
DROP TABLE  #DistinctACHRunDetails
END

GO
