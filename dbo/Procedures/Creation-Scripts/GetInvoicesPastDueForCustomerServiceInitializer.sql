SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesPastDueForCustomerServiceInitializer]
(
	@CustomerNumber nvarchar(50) ,
	@UserId BIGINT,
	@CurrentBusinessDate Datetime,
	@AccessibleLegalEntities NVARCHAR(MAX)
)
AS

BEGIN

--DECLARE @CustomerNumber nvarchar(80) = '10171933',
--@UserId BIGINT = 1,
--@CurrentBusinessDate Datetime = '2019-04-25 00:00:00',
--@AccessibleLegalEntities NVARCHAR(MAX) = =N'1,2,5,7,8,11,12,13,14,15,16,18,19,20,22,48,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114'

SET NOCOUNT ON
DECLARE @CustomerId BIGINT = (SELECT Id FROM Parties WHERE PartyNumber = @CustomerNumber)
DECLARE @DaysPastDue int
DECLARE @LastReceiptDate Datetime
DECLARE @OldestRentDueDate Datetime
DECLARE @NonRentPastDue_Amount Decimal(16,2)
DECLARE @NonRentPastDue_Currency NVARCHAR(3)
DECLARE @RentPastDue_Amount Decimal(16,2)
DECLARE @RentPastDue_Currency NVARCHAR(3)
DECLARE @NumberOfNSFs INT = 0

SELECT A.Id, L.ThresholdDays
INTO #AccessibleLegalEntityIds 
FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',') A
Join LegalEntities L On A.Id = L.Id

SELECT Id ReceivableTypeId INTO #ReceivableTypes FROM dbo.ReceivableTypes rt WHERE Name In('CapitalLeaseRental','OperatingLeaseRental','OverTermRental','Supplemental'
,'LoanInterest','LoanPrincipal','InterimRental','LeveragedLeaseRental','LeaseInterimInterest','LeaseFloatRateAdj')

SELECT 	RI.Id InvoiceId,
	#AccessibleLegalEntityIds.ThresholdDays,
	RI.CustomerId,
	RI.DueDate,
	RID.EffectiveBalance_Amount,
	RID.EffectiveBalance_Currency,
	RID.EffectiveTaxBalance_Amount,
	RC.ReceivableTypeId,
	RI.IsDummy,
	RID.Balance_Amount,
	RID.Balance_Currency ,
	RID.TaxBalance_Amount,
	RID.ReceivableDetailId
INTO #Invoices
FROM Receivables R
JOIN ReceivableInvoiceDetails RID ON RID.ReceivableId = R.Id
JOIN ReceivableInvoices as RI ON RI.Id = RID.ReceivableInvoiceId
INNER JOIN ReceivableCodes rc ON R.ReceivableCodeId = rc.Id
INNER JOIN #AccessibleLegalEntityIds ON RI.LegalEntityId = #AccessibleLegalEntityIds.Id
WHERE RI.CustomerId = @CustomerId
AND R.IsActive =1
AND RI.IsActive =1
AND RID.IsActive=1
AND (CreationSourceTable IS NULL OR (CreationSourceTable IS NOT NULL AND CreationSourceTable <> 'ReceivableForTransfer'))
OPTION (LOOP JOIN);

CREATE NONCLUSTERED INDEX IX_#Invoices_InvoiceId  On #Invoices(InvoiceId) INCLUDE (ThresholdDays, IsDummy, [ReceivableTypeId],[Balance_Amount],[TaxBalance_Amount],[DueDate])
CREATE NONCLUSTERED INDEX IX_#Invoices_DueDate  On #Invoices(DueDate) INCLUDE (ThresholdDays, IsDummy, [ReceivableTypeId],[Balance_Amount],[TaxBalance_Amount])

SELECT @DaysPastDue = ISNULL(MAX(DATEDIFF(Day,DATEADD(DD,I.ThresholdDays,I.DueDate),@CurrentBusinessDate)),0)
,@OldestRentDueDate = Min(I.DueDate)
FROM dbo.#Invoices I
WHERE I.IsDummy = 0 AND I.DueDate <= @CurrentBusinessDate
	AND (I.Balance_Amount + I.TaxBalance_Amount)  > 0

Declare @CTE_NonRentPastDue table(NonRentPastDue_Amount decimal(16,2),NonRentPastDue_Currency nvarchar(6))
Insert into @CTE_NonRentPastDue(NonRentPastDue_Amount , NonRentPastDue_Currency)
SELECT
	ISNULL(SUM(I.EffectiveBalance_Amount + I.EffectiveTaxBalance_Amount),0) NonRentPastDue_Amount
	, MIN(I.EffectiveBalance_Currency) NonRentPastDue_Currency
FROM #Invoices I
Left Join dbo.#ReceivableTypes ERT On
	ERT.ReceivableTypeId  = I.ReceivableTypeId
WHERE
	ERT.ReceivableTypeId Is Null
	AND (I.Balance_Amount + I.TaxBalance_Amount)  > 0 AND I.IsDummy = 0
GROUP BY I.DueDate HAVING DateDiff(Day,I.DueDate,@CurrentBusinessDate) > 0

SELECT @NonRentPastDue_Amount = ISNULL(SUM(NRPD.NonRentPastDue_Amount),0) ,@NonRentPastDue_Currency = ISNULL(MIN(NRPD.NonRentPastDue_Currency),'USD') FROM @CTE_NonRentPastDue AS NRPD

Declare @CTE_RentPastDue table(RentPastDue_Amount Decimal(18,2),RentPastDue_Currency nvarchar(6))
Insert into @CTE_RentPastDue(RentPastDue_Amount,RentPastDue_Currency)
SELECT
	ISNULL(SUM(I.Balance_Amount + I.TaxBalance_Amount),0) RentPastDue_Amount,
	MIN(I.Balance_Currency) RentPastDue_Currency
FROM
	#Invoices I
INNER JOIN #ReceivableTypes
ON I.ReceivableTypeId = #ReceivableTypes.ReceivableTypeId AND I.IsDummy = 0
GROUP BY I.DueDate HAVING DateDiff(Day,I.DueDate,@CurrentBusinessDate) > 0

SELECT @RentPastDue_Amount = ISNULL(SUM(RPD.RentPastDue_Amount),0), @RentPastDue_Currency =  ISNULL(MIN(RPD.RentPastDue_Currency),'USD') FROM @CTE_RentPastDue as RPD

SELECT rard.ReceiptApplicationId, I.DueDate
INTO #ReceiptApplications
FROM dbo.#Invoices I
JOIN dbo.ReceiptApplicationReceivableDetails rard
	ON I.InvoiceId = rard.ReceivableInvoiceId
	AND rard.IsActive=1
	AND I.IsDummy = 0
	AND I.ReceivableDetailId = rard.ReceivableDetailId
GROUP BY rard.ReceiptApplicationId, I.DueDate

INSERT INTO #ReceiptApplications
SELECT rard.ReceiptApplicationId, I.DueDate
FROM dbo.#Invoices I
JOIN dbo.ReceiptApplicationReceivableDetails rard
	ON I.InvoiceId = rard.ReceivableInvoiceId
	AND rard.IsActive=1
	AND I.IsDummy = 0
	AND I.ReceivableDetailId = rard.ReceivableDetailId
JOIN dbo.DSLReceiptHistories dh ON I.InvoiceId = dh.InvoiceId
	AND I.ReceivableDetailId = dh.ReceivableDetailId
	GROUP BY rard.ReceiptApplicationId, I.DueDate

SELECT r.Id ReceiptId,ReversalReasonId,TypeId,RA.DueDate,r.ReceivedDate, r.PostDate,r.Balance_Amount,r.Status
INTO #Receipts
FROM #ReceiptApplications RA
JOIN ReceiptApplications
	ON ReceiptApplications.Id = RA.ReceiptApplicationId
JOIN Receipts r
	ON r.id = ReceiptApplications.ReceiptId

SELECT @NumberOfNSFs = COUNT(DISTINCT r.ReceiptId) FROM #Receipts r
INNER JOIN ReceiptReversalReasons ON
r.ReversalReasonId = ReceiptReversalReasons.Id
INNER JOIN ReceiptTypes on
r.TypeId = ReceiptTypes.Id
WHERE  ReceiptReversalReasons.CreateReceivable = 1 AND r.DueDate <= @CurrentBusinessDate
AND ReceiptTypes.ReceiptTypeName <> 'PayDown'
AND (ReceiptTypes.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' OR r.Balance_Amount <> 0)

SELECT @LastReceiptDate = MAX(ISNULL(r.ReceivedDate,r.PostDate))   FROM dbo.#Receipts r
INNER JOIN ReceiptTypes on
r.TypeId = ReceiptTypes.Id
AND r.Status = 'Posted' AND r.ReceivedDate <= @CurrentBusinessDate AND r.PostDate <= @CurrentBusinessDate
AND ReceiptTypes.ReceiptTypeName <> 'PayDown'
AND ( ReceiptTypes.ReceiptTypeName <> 'WaivedFromReceivableAdjustment' OR r.Balance_Amount <> 0)

DROP TABLE #ReceivableTypes
DROP TABLE dbo.#Invoices
DROP TABLE dbo.#Receipts
DROP TABLE #AccessibleLegalEntityIds
DROP TABLE #ReceiptApplications
--DROP TABLE  #Receivables
--DROP TABLE  #ReceivableDetails
--DROP TABLE #ReceivableInvoiceDetails

SELECT
@DaysPastDue DaysPastDue
,@LastReceiptDate LastReceiptDate
,@OldestRentDueDate OldestRentDueDate
,@NonRentPastDue_Amount NonRentPastDue_Amount
,@NonRentPastDue_Currency NonRentPastDue_Currency
,@RentPastDue_Amount RentPastDue_Amount
,@RentPastDue_Currency RentPastDue_Currency
,@NumberOfNSFs NumberOfNSFs

END

GO
