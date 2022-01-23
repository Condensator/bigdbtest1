SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetGAICInsurancePaymentOutBoundInterface]
AS
;WITH CTE_ReceiptDetails
AS
(
SELECT
LeaseNumber=Contracts.SequenceNumber
,AmountCollected = ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
,ReceiptApplicationReceivableDetailID = ReceiptApplicationReceivableDetails.Id
,ReceiptsId = Receipts.Id
,Receipts.Status
FROM Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND LeaseFinances.GAICStatus='Acknowledged'
AND LeaseFinances.BookingStatus='Commenced'
AND SendToGAIC=1
INNER JOIN Receivables ON Contracts.Id=Receivables.EntityId
AND Receivables.EntityType='CT'
AND Receivables.IsActive=1
INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
AND ReceivableCodes.IsActive=1
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
AND ReceivableTypes.Name IN('InsurancePremium','InsurancePremiumAdmin')
AND ReceivableTypes.IsActive=1
INNER JOIN ReceivableDetails ON ReceivableDetails.ReceivableId=Receivables.Id
AND ReceivableDetails.Amount_Amount <> 0
AND ReceivableDetails.IsActive=1
INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
AND ReceiptApplicationReceivableDetails.IsActive=1
INNER JOIN ReceiptApplications ON ReceiptApplications.Id=ReceiptApplicationReceivableDetails.ReceiptApplicationId
INNER JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
WHERE
Receivables.IsActive=1
AND ReceivableDetails.IsActive=1
AND (DATEPART(mm,GetDate())-1)=DatePart(mm,Receipts.ReceivedDate)
AND DatePart(YYYY,GETDATE())=DatePart(YYYY,Receipts.ReceivedDate)
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber
,AmountCollected = ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount
,ReceiptApplicationReceivableDetailID = ReceiptApplicationReceivableDetails.Id
,ReceiptsId = Receipts.Id
,Receipts.Status
FROM Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
AND LoanFinances.GAICStatus='Acknowledged'
AND LoanFinances.Status='Commenced'
AND IsSendToGAIC=1
INNER JOIN Receivables ON Contracts.Id=Receivables.EntityId
AND Receivables.EntityType='CT'
AND Receivables.IsActive=1
INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
AND ReceivableCodes.IsActive=1
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
AND ReceivableTypes.Name IN('InsurancePremium','InsurancePremiumAdmin')
AND ReceivableTypes.IsActive=1
INNER JOIN ReceivableDetails ON ReceivableDetails.ReceivableId=Receivables.Id
AND ReceivableDetails.Amount_Amount <> 0
AND ReceivableDetails.IsActive=1
INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
AND ReceiptApplicationReceivableDetails.IsActive=1
INNER JOIN ReceiptApplications ON ReceiptApplications.Id=ReceiptApplicationReceivableDetails.ReceiptApplicationId
INNER JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
WHERE
Receivables.IsActive=1 AND ReceivableDetails.IsActive=1
AND (DATEPART(mm,GetDate())-1)=DatePart(mm,Receipts.ReceivedDate)
AND DatePart(YYYY,GETDATE())=DatePart(YYYY,Receipts.ReceivedDate)
)
,CTE_GroupByResult
AS
(
SELECT
LeaseNumber
,AmountCollected=Sum(AmountCollected)
,Status
,ReceiptApplicationReceivableDetailID = Min(ReceiptApplicationReceivableDetailID)
FROM CTE_ReceiptDetails
GROUP BY
LeaseNumber,
ReceiptsId,Status
)
,CTE_FinalReceiptList
AS
(
SELECT LeaseNumber,AmountCollected,ReceiptApplicationReceivableDetailID, 0 orderBy FROM CTE_GroupByResult
UNION ALL
SELECT LeaseNumber,AmountCollected = AmountCollected*(-1),ReceiptApplicationReceivableDetailID,1 orderBy FROM CTE_GroupByResult WHERE Status = 'Reversed'
)
Select LeaseNumber,AmountCollected,ReceiptApplicationReceivableDetailID from CTE_FinalReceiptList order by ReceiptApplicationReceivableDetailID ,orderBy

GO
