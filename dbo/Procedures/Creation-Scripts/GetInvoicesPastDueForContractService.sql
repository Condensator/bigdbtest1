SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesPastDueForContractService]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL,
@CurrentBusinessDate datetime,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')

 

SELECT
Case when DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 0 then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) else Cast(0 as decimal(16,2)) end TotalPastDue
,Case when DATEDIFF(Day,@CurrentBusinessDate,DATEADD(DD,LI.ThresholdDays,RI.DueDate)) >= 0 then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) else Cast(0 as decimal(16,2)) end CurrentlyDue
,Case when (DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 0 and DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) <= 30) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end ThirthyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 30 and DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) <= 60) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end SixtyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 60 and DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) <= 90) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end NinetyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 90 and DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) <= 120) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end NinetyOneDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 120) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end OneHundredTwentyPlusDayPastDue
,RI.CurrencyId
,CurrencyCodes.ISO
,RI.DueDate
INTO #ReceivableInvoices
FROM
Receivableinvoices as RI
INNER JOIN LegalEntities LI
on RI.LegalEntityId = LI.Id
AND LI.Status = 'Active'
INNER JOIN #AccessibleLegalEntityIds
ON LI.Id = #AccessibleLegalEntityIds.Id
INNER JOIN ReceivableInvoiceDetails as RID
on RI.Id = RID.ReceivableInvoiceId
AND RI.Isactive =1 and RI.IsDummy = 0
AND (@FilterCustomerId IS NULL OR RI.CustomerId = @FilterCustomerId )
AND RID.IsActive=1
INNER JOIN ReceivableCategories AS RC1
ON RID.ReceivableCategoryId = RC1.Id
Inner Join ReceivableDetails RD
on RID.ReceivableDetailId = RD.Id
AND RD.IsActive=1
Inner Join Receivables R
on RD.ReceivableId = R.Id
AND R.IsActive=1
AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'))
INNER JOIN Contracts C
on R.EntityId = C.Id
AND R.EntityType = 'CT'
AND C.SequenceNumber = @ContractSequenceNumber
INNER JOIN Currencies ON
Currencies.Id = RI.CurrencyId
AND Currencies.IsActive=1
INNER JOIN CurrencyCodes ON
CurrencyCodes.Id = Currencies.CurrencyCodeId
AND CurrencyCodes.IsActive=1
WHERE RC1.Name != 'AssetSale'
GROUP BY RI.CurrencyId,RI.DueDate,CurrencyCodes.ISO,LI.ThresholdDays
OPTION (LOOP JOIN)
 

SELECT
RID.ISO as Currency
,SUM(RID.CurrentlyDue) as CurrentlyDue
,SUM(RID.TotalPastDue) as TotalPastDue
,SUM(RID.ThirthyDayPastDue) as ZeroToThirtyDaysPastDue
,SUM(RID.SixtyDayPastDue) as ThirtyOneToSixtyDaysPastDue
,SUM(RID.NinetyDayPastDue) as SixtyOneToNinetyDaysPastDue
,SUM(RID.NinetyOneDayPastDue) as NinetyOneToOneHundredTwentyDaysPastDue
,SUM(RID.OneHundredTwentyPlusDayPastDue) AS OneHundredTwentyPlusDaysAndAbovePastDue
FROM
#ReceivableInvoices as RID
GROUP BY RID.CurrencyId,RID.ISO
DROP TABLE #AccessibleLegalEntityIds
DROP TABLE #ReceivableInvoices
END

GO
