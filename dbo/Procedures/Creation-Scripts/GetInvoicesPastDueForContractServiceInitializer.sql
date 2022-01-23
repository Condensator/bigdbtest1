SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesPastDueForContractServiceInitializer]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL,
@CurrentBusinessDate Datetime,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN

--DECLARE @ContractSequenceNumber nvarchar(80) = N'7180-1',
--@FilterCustomerId BIGINT = NULL,
--@CurrentBusinessDate Datetime = sysdatetimeoffset(),
--@AccessibleLegalEntities NVARCHAR(MAX)  = '1'

SET NOCOUNT ON
Declare @ContractId as bigint;
SET @ContractId = (Select Id from Contracts Where SequenceNumber = @ContractSequenceNumber)
DECLARE @DaysPastDue int
DECLARE @LastReceiptDate Datetime
DECLARE @OldestRentDueDate Datetime
DECLARE @NonRentPastDue Decimal(16,2)
DECLARE @RentPastDue Decimal(16,2)
DECLARE @NumberOfNSFs INT = 0

SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')

SELECT Id ReceivableTypeId INTO #ReceivableTypes FROM dbo.ReceivableTypes rt WHERE Name In('CapitalLeaseRental','OperatingLeaseRental','OverTermRental','Supplemental'
,'LoanInterest','LoanPrincipal','InterimRental','LeveragedLeaseRental','LeaseInterimInterest','LeaseFloatRateAdj')

Select Id,ReceivableCodeId Into #Receivables From Receivables
	Where EntityId = @ContractId
	AND EntityType = 'CT'
	AND IsActive = 1
	AND SourceTable NOT IN ('CPUSchedule')
	AND (CreationSourceTable IS NULL OR (CreationSourceTable IS NOT NULL AND CreationSourceTable <> 'ReceivableForTransfer'))

Select
RD.Id,rc.ReceivableTypeId
Into #ReceivableDetails
From ReceivableDetails RD
Inner Join #Receivables R
on RD.ReceivableId = R.Id
INNER JOIN ReceivableCodes rc ON
R.ReceivableCodeId = rc.Id
WHERE RD.IsActive = 1

SELECT RI.Id InvoiceId,le.ThresholdDays,RI.CustomerId, RI.DueDate, RID.EffectiveBalance_Amount,
RID.EffectiveTaxBalance_Amount, RD.ReceivableTypeId, RI.IsDummy,RID.Balance_Amount , RID.TaxBalance_Amount INTO #Invoices
FROM
ReceivableInvoices as RI
INNER JOIN ReceivableInvoiceDetails as RID  on RI.Id = RID.ReceivableInvoiceId
INNER JOIN ReceivableCategories AS RC1  ON RID.ReceivableCategoryId = RC1.Id
INNER JOIN dbo.LegalEntities le on RI.LegalEntityId = le.Id
INNER JOIN #AccessibleLegalEntityIds ON le.Id = #AccessibleLegalEntityIds.Id
Inner Join #ReceivableDetails RD  on RID.ReceivableDetailId = RD.Id
WHERE RI.IsActive = 1
AND RI.Balance_Amount + RI.TaxBalance_Amount <> 0.00
AND RC1.Name != 'AssetSale'
AND (@FilterCustomerId IS NULL OR RI.CustomerId = @FilterCustomerId )

SELECT @DaysPastDue = ISNULL(MAX(DATEDIFF(Day,DATEADD(DD,i.ThresholdDays,i.DueDate),@CurrentBusinessDate)),0) FROM dbo.#Invoices i
WHERE i.IsDummy = 0 AND i.DueDate <= @CurrentBusinessDate
AND (i.Balance_Amount + i.TaxBalance_Amount)  > 0

SELECT @OldestRentDueDate = Min(i.DueDate) FROM dbo.#Invoices i
INNER JOIN #ReceivableTypes
ON i.ReceivableTypeId = #ReceivableTypes.ReceivableTypeId
AND i.IsDummy = 0 AND i.DueDate <= @CurrentBusinessDate
AND (i.Balance_Amount + i.TaxBalance_Amount)  > 0

;WITH CTE_NonRentPastDue AS
(
SELECT ISNULL(SUM(i.EffectiveBalance_Amount + i.EffectiveTaxBalance_Amount),0) NonRentPastDue FROM #Invoices i
WHERE i.ReceivableTypeId NOT IN (SELECT ReceivableTypeId FROM dbo.#ReceivableTypes)
AND i.IsDummy = 0
GROUP BY i.CustomerId,i.DueDate HAVING DateDiff(Day,i.DueDate,@CurrentBusinessDate) > 0
)
SELECT @NonRentPastDue = ISNULL(SUM(NRPD.NonRentPastDue),0) FROM CTE_NonRentPastDue AS NRPD WHERE NRPD.NonRentPastDue > 0
;WITH CTE_RentPastDue AS
(
SELECT ISNULL(SUM(i.Balance_Amount + i.TaxBalance_Amount),0) RentPastDue FROM #Invoices i
INNER JOIN #ReceivableTypes
ON i.ReceivableTypeId = #ReceivableTypes.ReceivableTypeId AND i.IsDummy = 0
GROUP BY i.CustomerId,i.DueDate HAVING DateDiff(Day,i.DueDate,@CurrentBusinessDate) > 0
)
SELECT @RentPastDue = ISNULL(SUM(RPD.RentPastDue),0) FROM CTE_RentPastDue as RPD


SELECT rard.ReceiptApplicationId, i.DueDate INTO #ReceiptApplications FROM dbo.#Invoices i
JOIN dbo.ReceiptApplicationReceivableDetails rard
	ON i.InvoiceId = rard.ReceivableInvoiceId AND rard.IsActive=1 AND i.IsDummy = 0
GROUP BY rard.ReceiptApplicationId, i.DueDate

INSERT INTO #ReceiptApplications
SELECT rard.ReceiptApplicationId, i.DueDate  FROM dbo.#Invoices i
JOIN dbo.ReceiptApplicationReceivableDetails rard
	ON i.InvoiceId = rard.ReceivableInvoiceId AND rard.IsActive=1 AND i.IsDummy = 0
JOIN dbo.DSLReceiptHistories dh ON i.InvoiceId = dh.InvoiceId
GROUP BY rard.ReceiptApplicationId, i.DueDate

Select recd.Id,rec.DueDate Into #ReceivableDetail
FROM Receivables rec
JOIN ReceivableDetails recd
	on rec.id = recd.ReceivableId
	AND rec.EntityId = @ContractId AND rec.EntityType = 'CT'
	and recd.IsActive = 1 and rec.IsActive = 1
	AND rec.IsDummy = 0

INSERT INTO #ReceiptApplications
SELECT rard.ReceiptApplicationId, rec.DueDate FROM #ReceivableDetail rec
JOIN dbo.ReceiptApplicationReceivableDetails rard
	ON rec.Id = rard.ReceivableDetailId AND rard.IsActive=1
GROUP BY rard.ReceiptApplicationId, rec.DueDate

SELECT r.Id ReceiptId, ReversalReasonId, TypeId, RA.DueDate, r.ReceivedDate, r.PostDate,r.Balance_Amount,r.Status INTO #Receipts  FROM #ReceiptApplications RA
JOIN ReceiptApplications ON ReceiptApplications.Id = RA.ReceiptApplicationId
JOIN Receipts r ON r.id = ReceiptApplications.ReceiptId

SELECT @NumberOfNSFs = COUNT(DISTINCT r.ReceiptId) FROM #Receipts r
INNER JOIN ReceiptReversalReasons ON
r.ReversalReasonId = ReceiptReversalReasons.Id
INNER JOIN ReceiptTypes on
r.TypeId = ReceiptTypes.Id
WHERE  ReceiptReversalReasons.CreateReceivable = 1 AND r.DueDate <= @CurrentBusinessDate
AND ReceiptTypes.ReceiptTypeName <> 'PayDown'
AND (ReceiptTypes.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' OR r.Balance_Amount <> 0)
SELECT @LastReceiptDate = MAX(COALESCE(r.ReceivedDate,r.PostDate))   FROM dbo.#Receipts r
INNER JOIN ReceiptTypes on
r.TypeId = ReceiptTypes.Id
AND r.Status = 'Posted' AND r.ReceivedDate <= @CurrentBusinessDate AND r.PostDate <= @CurrentBusinessDate
AND ReceiptTypes.ReceiptTypeName <> 'PayDown'
AND ( ReceiptTypes.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' OR r.Balance_Amount <> 0)

DROP TABLE #ReceivableTypes
DROP TABLE dbo.#Invoices
DROP TABLE dbo.#Receipts
DROP TABLE #ReceivableDetails
DROP TABLE #ReceivableDetail
DROP TABLE #Receivables
DROP TABLE #AccessibleLegalEntityIds
DROP TABLE #ReceiptApplications

SELECT
CASE WHEN  @DaysPastDue >= 0
THEN  @DaysPastDue
ELSE  0 END AS DaysPastDue
,@LastReceiptDate LastReceiptDate
,@OldestRentDueDate OldestRentDueDate
,@NonRentPastDue NonRentPastDue
,@RentPastDue RentPastDue
,@NumberOfNSFs NumberOfNSFs
END

GO
