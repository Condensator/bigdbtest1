SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoiceSummariesForCustomerService]
(
	@CustomerNumber NVARCHAR(50),
	@Error NVARCHAR(10),
	@CurrentBusinessDate datetime,
	@AccessibleLegalEntities NVARCHAR(MAX)
)
AS

BEGIN

--DECLARE
--	@CustomerNumber NVARCHAR(50) = '10171547',
--	@Error NVARCHAR(10) = 'Error',
--	@CurrentBusinessDate datetime = '2019-04-25 00:00:00',
--	@AccessibleLegalEntities NVARCHAR(MAX) = N'1,2,5,7,11,13,19,20,22,48,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114'

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON

SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')

DECLARE @CustomerId BIGINT = (SELECT Id FROM Parties where PartyNumber = @CustomerNumber)

SELECT RD.Id AS ReceivableInvoiceId,IsBelongsToStatementInvoice = 1
INTO #StatementDetails
FROM ReceivableInvoices RD
JOIN ReceivableInvoiceStatementAssociations SI ON RD.Id = SI.ReceivableInvoiceId
WHERE
RD.Isactive = 1
AND SI.IsCurrentInvoice = 1
AND RD.IsDummy = 0
AND RD.CustomerId = @CustomerId

SELECT RI.Id ReceivableInvoiceId, RID.ReceivableCategoryId,RD.Id,
RD.Amount_Amount,RD.Balance_Amount AS ReceivableBalance,
RID.Balance_Amount InvoiceBalance,RID.TaxBalance_Amount InvoiceTaxBalance,
RID.EffectiveBalance_Amount,RID.EffectiveTaxBalance_Amount
INTO #ReceivableInvoiceDetails
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = Rd.ReceivableId
JOIN ReceivableInvoiceDetails RID ON RID.ReceivableDetailId = RD.Id
JOIN ReceivableInvoices RI ON RI.Id = RID.ReceivableInvoiceId
WHERE RI.CustomerId = @CustomerId
AND R.IsActive = 1
AND RD.IsActive = 1
AND RD.BilledStatus = 'Invoiced'
AND RID.IsActive = 1
AND RI.IsActive = 1
AND RI.IsDummy = 0
AND RI.IsStatementInvoice = 0
AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'))
OPTION (Loop JOIN);

SELECT  ReceivableInvoiceId, ReceivableCategoryId,
SUM(Amount_Amount) AS ReceivableAmount,SUM(ReceivableBalance) ReceivableBalance,
SUM(InvoiceBalance) InvoiceBalance,SUM( InvoiceTaxBalance) InvoiceTaxBalance,
SUM(EffectiveBalance_Amount) EffectiveBalance_Amount,SUM(EffectiveTaxBalance_Amount) EffectiveTaxBalance_Amount
INTO #ReceivableInvoices FROM #ReceivableInvoiceDetails
GROUP BY ReceivableInvoiceId, ReceivableCategoryId 

SELECT  RI.Number AS InvoiceNumber,
IT.Name AS InvoiceType,
RI.IsActive AS Status,
RI.InvoiceRunDate AS RunDate,
RI.DueDate AS DueDate,
#AccessibleLegalEntityIds.Id AS LegalEntityId,
RI.InvoiceAmount_Amount AS ChargeAmount,
RI.InvoiceTaxAmount_Amount AS TaxAmount,
RI.InvoiceAmount_Amount + RI.InvoiceTaxAmount_Amount AS InvoiceAmount,
BT.Name AS InvoiceGroup,
PA.AddressLine1+ISNULL(','+Pa.AddressLine2, '')+IsNULL(','+PA.City, '')+ISNULL(','+S.LongName, '')+IsNull(','+PA.Division, '')+IsNull(','+PA.PostalCode, '') AS InvoiceGroupAddress,
PC.FullName AS ContactPerson,
RI.Id ReceivableInvoiceID,
CurrCode.ISO AS Currency,
RI.InvoiceFile_Source,
RI.InvoiceFile_Type,
RI.InvoiceFile_Content,
CASE
WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
THEN NULL
ELSE RI.InvoiceRunDate
END AS GeneratedDate,
RI.IsPdfGenerated AS IsGenerated,
RI.DeliveryDate,
CASE
WHEN RI.DeliveryMethod = '_' OR RI.DeliveryMethod IS NULL
THEN CASE
WHEN RI.StatementInvoicePreference = 'SuppressDelivery'
THEN RI.StatementInvoicePreference
ELSE CASE
WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
THEN RI.StatementInvoicePreference
ELSE CASE
WHEN RI.DeliveryJobStepInstanceId IS NULL
THEN '_'
ELSE CASE
WHEN RI.DeliveryJobStepInstanceId IS NOT NULL
AND RI.IsEmailSent = 0
THEN @Error
END
END
END
END
ELSE RI.DeliveryMethod
END
 AS DeliveryMethod,
RI.IsActive,
RI.IsStatementInvoice,
RI.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount,
RI.WithHoldingTaxBalance_Amount AS WithHoldingTaxBalance,
rid.ReceivableAmount,rid.ReceivableBalance,
rid.InvoiceBalance,rid.InvoiceTaxBalance,
rid.EffectiveBalance_Amount,rid.EffectiveTaxBalance_Amount
INTO #InvoiceSummaries
FROM
	ReceivableInvoices RI
INNER JOIN #ReceivableInvoices rid
	ON RI.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.LegalEntities le
	ON RI.LegalEntityId = le.Id
INNER JOIN #AccessibleLegalEntityIds
	ON le.Id = #AccessibleLegalEntityIds.Id
INNER JOIN Customers C
	ON RI.CustomerId = C.Id
INNER JOIN ReceivableCategories RC
	ON rid.ReceivableCategoryId = RC.Id
INNER JOIN BillToes BT
	ON Ri.BillToId = BT.Id
INNER JOIN RemitToes RT
	ON RI.RemitToId = RT.Id
INNER JOIN InvoiceTypes IT
	ON RC.InvoiceTypeId = IT.Id
INNER JOIN Currencies Curr
	ON RI.CurrencyId = Curr.Id
INNER JOIN CurrencyCodes CurrCode
	ON Curr.CurrencyCodeId = CurrCode.Id
LEFT JOIN PartyAddresses PA
	ON BT.BillingAddressId = PA.Id
LEFT JOIN States S
	ON Pa.StateId = S.Id
LEFT JOIN PartyContacts PC
	ON BT.BillingContactPersonId = PC.Id;

Update
	InvS
Set
	DeliveryMethod = 'SuppressGeneration'
from #InvoiceSummaries InvS
Inner Join #StatementDetails SD On
	SD.ReceivableInvoiceId = InvS.ReceivableInvoiceID

DECLARE @SYSDATE DATE;
SET @SYSDATE = @CurrentBusinessDate;

	SELECT
		RD.ReceivableInvoiceId ,
		SUM(RTD.Amount_Amount) AS OriginalTaxAmount,
		SUM(RTD.Balance_Amount) AS OriginalTaxBalance
		into #cte_ReceivableTaxDetails
	FROM
	#ReceivableInvoiceDetails Rd
	INNER JOIN REceivableTaxDetails RTD
		ON Rd.Id = RTD.ReceivableDetailId
	WHERE  RTD.IsActive=1
	GROUP BY RD.ReceivableInvoiceId
	OPTION (LOOP JOIN);

	SELECT SUM(RI.ReceivableAmount + RTD.OriginalTaxAmount) - SUM(RI.ReceivableBalance + RTD.OriginalTaxBalance) AS AmountReceived,
		SUM(RI.ReceivableAmount) OriginalAmount,
		SUM(RTD.OriginalTaxAmount) OriginalTaxAmount,
		SUM(RI.InvoiceBalance + RI.InvoiceTaxBalance) AS OutstandingBalance,
		CASE
		WHEN SUM(RI.InvoiceBalance + RI.InvoiceTaxBalance) = 0
		THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
		END AS IsPaid,
		CASE
		WHEN DATEDIFF(DAY,DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) <  = 30
		AND DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) > 0
		THEN SUM(RI.EffectiveBalance_Amount + RI.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ZeroToThirtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) <  = 60
		AND DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) > 30
		THEN SUM(RI.EffectiveBalance_Amount + RI.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ThirtyOneToSixtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) <  = 90
		AND DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) > 60
		THEN SUM(RI.EffectiveBalance_Amount + RI.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS SixtyOneToNinetyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) <= 120
		AND DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) > 90
		THEN SUM(RI.EffectiveBalance_Amount + RI.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS NinetyOneToOneHundredTwentyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,le.ThresholdDays,RI.DueDate), @SYSDATE) > 120
		THEN SUM(RI.EffectiveBalance_Amount + RI.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS OneHundredTwentyPlusDaysAndAbove,
		RI.ReceivableInvoiceID
		into #cte_ReceivableInvoiceDetails
	FROM #InvoiceSummaries RI
	INNER JOIN dbo.LegalEntities le
		ON RI.LegalEntityId = le.Id
	Inner Join #cte_ReceivableTaxDetails RTD On
		RTD.ReceivableInvoiceId  = RI.ReceivableInvoiceID
	GROUP BY
		RI.ReceivableInvoiceID,
		RI.DueDate,
		le.ThresholdDays

CREATE NONClustered INDEX IX_ReceivableInviceId on #cte_ReceivableInvoiceDetails (ReceivableInvoiceID)

SELECT
	SUM(RARD.AmountApplied_Amount + RARD.TaxApplied_Amount) AmountWaived,
	RI.ReceivableInvoiceId
INTO #cte_receiptDetails
FROM #cte_ReceivableInvoiceDetails RI
INNER JOIN ReceivableInvoiceDetails RID
	ON RI.ReceivableInvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceiptApplicationReceivableDetails RARD
	ON RARD.ReceivableInvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceiptApplications
	ON ReceiptApplications.Id = RARD.ReceiptApplicationId
INNER JOIN Receipts
	ON Receipts.id = ReceiptApplications.ReceiptId
INNER JOIN ReceiptTypes
	ON Receipts.TypeId = ReceiptTypes.Id
WHERE
	RARD.IsActive = 1
	AND RID.IsActive=1
	AND ((Receipts.Status = 'Completed'
	AND Receipts.ReceiptClassification IN('NonCash', 'NonAccrualNonDSLNonCash'))
	OR (Receipts.Status = 'Posted'
	AND ReceiptTypes.ReceiptTypeName = 'WaivedFromReceivableAdjustment'))
GROUP BY RI.ReceivableInvoiceId

SELECT RI.InvoiceNumber,
RI.IsStatementInvoice,
RID.OriginalAmount,
ISNULL(RID.OriginalTaxAmount, 0.00) OriginalTaxAmount,
RI.InvoiceType,
RI.Status,
RI.RunDate,
RI.DueDate,
RI.ChargeAmount,
RI.TaxAmount,
RI.InvoiceAmount,
RID.AmountReceived [AmountReceived],
CASE WHEN RI.IsActive = 0 THEN 0 ELSE RID.OutstandingBalance END OutstandingBalance,
RID.IsPaid,
RID.ZeroToThirtyDays,
RID.ThirtyOneToSixtyDays,
RID.SixtyOneToNinetyDays,
RID.NinetyOneToOneHundredTwentyDays,
RID.OneHundredTwentyPlusDaysAndAbove,
RI.InvoiceGroup,
RI.InvoiceGroupAddress,
RI.ContactPerson,
RI.Currency,
RI.ReceivableInvoiceID InvoiceId,
 CAST(0.00 as decimal) [AmountWaived],
RID.AmountReceived  [TotalPaid],
RI.InvoiceFile_Source,
RI.InvoiceFile_Type,
RI.InvoiceFile_Content,
RI.GeneratedDate,
RI.IsGenerated,
RI.DeliveryDate,
RI.DeliveryMethod,
RI.ReceivableInvoiceID,
RI.WithHoldingTaxAmount AS WithHoldingTaxAmount,
RI.WithHoldingTaxBalance AS WithHoldingTaxBalance
into #Result
FROM #InvoiceSummaries AS RI
INNER JOIN #cte_ReceivableInvoiceDetails AS RID ON RID.ReceivableInvoiceID = RI.ReceivableInvoiceID

Update R
Set
 R.AmountReceived = Case WHEN RD.AmountWaived IS NOT NULL AND RD.AmountWaived > 0 AND RID.AmountReceived > 0
					THEN RID.AmountReceived - RD.AmountWaived
					ELSE RID.AmountReceived end
,R.AmountWaived = CASE WHEN RD.AmountWaived IS NOT NULL THEN RD.AmountWaived ELSE 0 END
,R.TotalPaid = CASE WHEN R.InvoiceType = 'LateCharge' AND RD.AmountWaived = RID.AmountReceived
				THEN CAST(0.00 as decimal) ELSE RID.AmountReceived END
From #Result R
INNER JOIN #cte_ReceivableInvoiceDetails AS RID ON RID.ReceivableInvoiceID = R.ReceivableInvoiceID
Inner Join #cte_receiptDetails RD ON RD.ReceivableInvoiceID = R.ReceivableInvoiceID;

Select InvoiceNumber,
IsStatementInvoice,
OriginalAmount,
 OriginalTaxAmount,
InvoiceType,
Status,
RunDate,
DueDate,
ChargeAmount,
TaxAmount,
InvoiceAmount,
 [AmountReceived],
OutstandingBalance,
IsPaid,
ZeroToThirtyDays,
ThirtyOneToSixtyDays,
SixtyOneToNinetyDays,
NinetyOneToOneHundredTwentyDays,
OneHundredTwentyPlusDaysAndAbove,
InvoiceGroup,
InvoiceGroupAddress,
ContactPerson,
Currency,
InvoiceId,
[AmountWaived],
TotalPaid,
InvoiceFile_Source,
InvoiceFile_Type,
InvoiceFile_Content,
GeneratedDate,
IsGenerated,
DeliveryDate,
DeliveryMethod,
WithHoldingTaxAmount AS WithHoldingTaxAmount,
WithHoldingTaxBalance AS WithHoldingTaxBalance
FROM #Result
UNION
(
SELECT
RI.Number AS InvoiceNumber,
RI.IsStatementInvoice,
RI.InvoiceAmount_Amount,
ISNULL(RI.InvoiceTaxAmount_Amount, 0.00) OriginalTaxAmount,
IT.Name AS InvoiceType,
RI.IsActive AS Status,
RI.InvoiceRunDate AS RunDate,
RI.DueDate,
RI.InvoiceAmount_Amount AS ChargeAmount,
RI.InvoiceTaxAmount_Amount AS TaxAmount,
RI.InvoiceAmount_Amount + RI.InvoiceTaxAmount_Amount AS InvoiceAmount,
(RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount)[AmountReceived],
CASE WHEN RI.IsActive = 0 THEN 0 ELSE (RI.Balance_Amount + RI.TaxBalance_Amount) END OutstandingBalance,
CASE
WHEN RI.Balance_Amount + RI.TaxBalance_Amount= 0
THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END AS IsPaid,
CASE
WHEN DATEDIFF(DAY,DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) <  = 30
AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) > 0
THEN RI.Balance_Amount + RI.TaxBalance_Amount
ELSE CAST(0 AS DECIMAL(16, 2))
END AS ZeroToThirtyDays,
CASE
WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) <  = 60
AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) > 30
THEN RI.Balance_Amount + RI.TaxBalance_Amount
ELSE CAST(0 AS DECIMAL(16, 2))
END AS ThirtyOneToSixtyDays,
CASE
WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) <  = 90
AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) > 60
THEN RI.Balance_Amount + RI.TaxBalance_Amount
ELSE CAST(0 AS DECIMAL(16, 2))
END AS SixtyOneToNinetyDays,
CASE
WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) <= 120
AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) > 90
THEN RI.Balance_Amount + RI.TaxBalance_Amount
ELSE CAST(0 AS DECIMAL(16, 2))
END AS NinetyOneToOneHundredTwentyDays,
CASE
WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @SYSDATE) > 120
THEN RI.Balance_Amount + RI.TaxBalance_Amount
ELSE CAST(0 AS DECIMAL(16, 2))
END AS OneHundredTwentyPlusDaysAndAbove,
BT.Name AS InvoiceGroup,
PA.AddressLine1+ISNULL(','+Pa.AddressLine2, '')+IsNULL(','+PA.City, '')+ISNULL(','+S.LongName, '')+IsNull(','+PA.Division, '')+IsNull(','+PA.PostalCode, '') AS InvoiceGroupAddress,
PC.FullName AS ContactPerson,
CurrCode.ISO AS Currency,
RI.Id InvoiceId,
CASE
WHEN  (RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount) IS NOT NULL
THEN  (RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount)
ELSE 0
END [AmountWaived],
(RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount) [TotalPaid],
RI.InvoiceFile_Source,
RI.InvoiceFile_Type,
RI.InvoiceFile_Content,
CASE
WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
THEN NULL
ELSE RI.InvoiceRunDate
END AS GeneratedDate,
RI.IsPdfGenerated AS IsGenerated,
RI.DeliveryDate,
CASE
WHEN RI.DeliveryMethod = '_' OR RI.DeliveryMethod IS NULL
THEN CASE
WHEN RI.StatementInvoicePreference = 'SuppressDelivery'
THEN RI.StatementInvoicePreference
ELSE CASE
WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
THEN RI.StatementInvoicePreference
ELSE CASE
WHEN RI.DeliveryJobStepInstanceId IS NULL
THEN '_'
ELSE CASE
WHEN RI.DeliveryJobStepInstanceId IS NOT NULL
AND RI.IsEmailSent = 0
THEN @Error
END
END
END
END
ELSE RI.DeliveryMethod
END AS DeliveryMethod,
RI.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount,
RI.WithHoldingTaxBalance_Amount AS WithHoldingTaxBalance
FROM ReceivableInvoices AS RI
INNER JOIN dbo.LegalEntities LE ON RI.LegalEntityId = le.Id
	And RI.CustomerId = @CustomerId
INNER JOIN #AccessibleLegalEntityIds ON le.Id = #AccessibleLegalEntityIds.Id
INNER JOIN Customers C ON RI.CustomerId = C.Id
AND RI.IsDummy = 0
INNER JOIN ReceivableCategories RC ON ri.ReceivableCategoryId = RC.Id
INNER JOIN BillToes BT ON Ri.BillToId = BT.Id
INNER JOIN RemitToes RT ON RI.RemitToId = RT.Id
INNER JOIN InvoiceTypes IT ON RC.InvoiceTypeId = IT.Id
INNER JOIN Currencies Curr ON RI.CurrencyId = Curr.Id
INNER JOIN CurrencyCodes CurrCode ON Curr.CurrencyCodeId = CurrCode.Id
LEFT JOIN PartyAddresses PA ON BT.BillingAddressId = PA.Id
LEFT JOIN States S ON Pa.StateId = S.Id
LEFT JOIN PartyContacts PC ON BT.BillingContactPersonId = PC.Id
WHERE RI.IsActive=1 AND RI.IsStatementInvoice = 1);

SELECT
SUM(ChargeAmount) ChargeAmount,
SUM(TaxAmount) TaxAmount,
SUM(InvoiceAmount) InvoiceAmount,
SUM(AmountReceived) AmountReceived,
SUM(OutstandingBalance) OutstandingBalance,
SUM(WithHoldingTaxAmount) WithHoldingTaxAmount,
SUM(WithHoldingTaxBalance) WithHoldingTaxBalance,
SUM(ZeroToThirtyDays) ZeroToThirtyDays ,
SUM(ThirtyOneToSixtyDays) ThirtyOneToSixtyDays,
SUM(SixtyOneToNinetyDays) SixtyOneToNinetyDays ,
SUM(NinetyOneToOneHundredTwentyDays) NinetyOneToOneHundredTwentyDays,
SUM(OneHundredTwentyPlusDaysAndAbove) OneHundredTwentyPlusDaysAndAbove ,
SUM(AmountWaived) AmountWaived,
SUM(TotalPaid) TotalPaid
FROM #Result

DROP TABLE IF EXISTS #ReceivableInvoices
DROP TABLE IF EXISTS #InvoiceSummaries
DROP TABLE IF EXISTS #AccessibleLegalEntityIds
DROP TABLE IF EXISTS #StatementDetails
DROP TABLE IF EXISTS #Result
DROP TABLE IF EXISTS #cte_ReceivableInvoiceDetails
DROP TABLE IF EXISTS #cte_receiptDetails
DROP TABLE IF EXISTS #cte_ReceivableTaxDetails
drop table IF EXISTS #Invoices
drop table IF EXISTS #ReceivableInvoiceDetails

END;

GO
