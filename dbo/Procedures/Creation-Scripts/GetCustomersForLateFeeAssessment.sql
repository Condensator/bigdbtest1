SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[GetCustomersForLateFeeAssessment]
(
@LegalEntityIdsToBeConsidered LegalEntityIdsToBeConsidered READONLY,
@ProcessThroughDate DATE,
@SystemDate DATE,
@EntityType NVARCHAR(2)
)
AS
  
--DECLARE  
--@ProcessThroughDate DATE = '4/25/2019',  
--@SystemDate DATE= '2019-04-10',  
--@EntityType NVARCHAR(2) = 'CT'  
  
BEGIN  
SET NOCOUNT ON  
  
SELECT LegalEntities.Id INTO #LegalEntityIdsToBeConsidered
FROM @LegalEntityIdsToBeConsidered S
JOIN LegalEntities ON S.LegalEntityId = LegalEntities.Id
WHERE LegalEntities.LateFeeApproach <> 'ReceiptBased'
  
SELECT DISTINCT ReceivableInvoices.CustomerId
,ReceivableInvoices.Id AS InvoiceId
,ReceivableInvoices.DueDate InvoiceDueDate
,ContractLateFees.InvoiceGraceDays
,Contracts.Id ContractId
,CAST(0 AS BIT) IsFirstInvoice
,CAST(1 AS BIT) IsEligible
,ContractLateFees.WaiveIfInvoiceAmountBelow_Amount WaiveIfInvoiceAmountBelowAmount
INTO #InvoiceInfo
FROM ReceivableInvoices  
INNER JOIN #LegalEntityIdsToBeConsidered on ReceivableInvoices.LegalEntityId = #LegalEntityIdsToBeConsidered.Id  
INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId   
AND ReceivableInvoiceDetails.EntityType = @EntityType  
INNER JOIN Contracts ON  Contracts.Id = ReceivableInvoiceDetails.EntityId  
INNER JOIN ContractLateFees ON Contracts.Id = ContractLateFees.Id AND ContractLateFees.LateFeeTemplateId IS NOT NULL  
LEFT JOIN LateFeeAssessments ON ReceivableInvoices.Id = LateFeeAssessments.ReceivableInvoiceId and Contracts.Id = LateFeeAssessments.ContractId  
WHERE ReceivableInvoices.IsActive=1 AND ReceivableInvoiceDetails.IsActive=1  
AND ReceivableInvoices.DueDate <= @SystemDate AND ReceivableInvoices.DueDate <= @ProcessThroughDate  
AND ReceivableInvoices.IsDummy = 0  
AND Contracts.Status <> 'Terminated'  
AND (ReceivableInvoices.Balance_Amount > 0 OR ReceivableInvoices.TaxBalance_Amount > 0 OR ReceivableInvoices.LastReceivedDate IS NULL OR ReceivableInvoices.LastReceivedDate > ReceivableInvoices.DueDate)  
AND (LateFeeAssessments.ReceivableInvoiceId IS NULL OR (LateFeeAssessments.FullyAssessed = 0 AND LateFeeAssessments.LateFeeAssessedUntilDate < @ProcessThroughDate))  

;WITH Contract_CTE AS 
(SELECT #InvoiceInfo.ContractId,MIN(ReceivableInvoices.DueDate) FirstInvoiceDueDate
FROM #InvoiceInfo
INNER JOIN ReceivableInvoiceDetails ON #InvoiceInfo.ContractId = ReceivableInvoiceDetails.EntityId
AND ReceivableInvoiceDetails.EntityType = @EntityType 
INNER JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1
where ReceivableInvoiceDetails.IsActive=1
GROUP BY #InvoiceInfo.ContractId)

Update I set IsFirstInvoice = 1
from #InvoiceInfo I
inner join Contract_CTE C on I.contractId = C.ContractId
where I.InvoiceDueDate = C.FirstInvoiceDueDate

Update I set InvoiceGraceDays = C.InvoiceGraceDaysAtInception
from #InvoiceInfo I
inner join ContractLateFees C on I.contractId = C.Id
where I.IsFirstInvoice = 1 and C.InvoiceGraceDaysAtInception <> 0

Update I set IsEligible = 0
from #InvoiceInfo I
INNER JOIN ReceivableInvoices ON I.InvoiceId = ReceivableInvoices.Id
WHERE (ReceivableInvoices.InvoiceAmount_Amount + ReceivableInvoices.InvoiceTaxAmount_Amount) < I.WaiveIfInvoiceAmountBelowAmount

Update #InvoiceInfo set IsEligible = 0 Where DATEADD(DAY,InvoiceGraceDays,InvoiceDueDate ) > @SystemDate AND IsEligible <> 0

Select DISTINCT CustomerId FROM #InvoiceInfo WHERE IsEligible = 1;

DROP TABLE #InvoiceInfo
DROP TABLE #LegalEntityIdsToBeConsidered  
  
END

GO
