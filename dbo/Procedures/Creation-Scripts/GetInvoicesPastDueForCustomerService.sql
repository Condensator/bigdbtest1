SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInvoicesPastDueForCustomerService]
(
@CustomerNumber nvarchar(80),
@CurrentBusinessDate datetime,
@AccessibleLegalEntities nvarchar(max)
)
AS
SET NOCOUNT ON
BEGIN
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')
;with CTE_RID as (
SELECT
Case when DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 0 then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) else Cast(0 as decimal(16,2)) end TotalPastDue
,Case when DATEDIFF(Day,@CurrentBusinessDate,DATEADD(DD,le.ThresholdDays,RD.DueDate)) >= 0 then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) else Cast(0 as decimal(16,2)) end CurrentlyDue
,Case when (DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 0 and DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) <= 30) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end ThirthyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 30 and DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) <= 60) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end SixtyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 60 and DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) <= 90) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end NinetyDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 90 and DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) <= 120) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end NinetyOneDayPastDue
,Case when (DATEDIFF(Day,DATEADD(DD,le.ThresholdDays,RD.DueDate),@CurrentBusinessDate) > 120) then SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount) Else 0 end OneHundredTwentyPlusDayPastDue
,RD.CurrencyId
,CurrencyCodes.ISO
,RD.DueDate
FROM
Receivableinvoices as RD
INNER JOIN dbo.LegalEntities le ON
RD.LegalEntityId = le.Id
INNER JOIN #AccessibleLegalEntityIds ON
RD.LegalEntityId = #AccessibleLegalEntityIds.Id
INNER JOIN Parties P on
RD.CustomerId = P.Id AND P.PartyNumber = @CustomerNumber AND RD.IsActive = 1 AND RD.IsDummy = 0
INNER JOIN ReceivableInvoiceDetails AS RID ON
RD.Id = RID.ReceivableInvoiceId AND RID.IsActive = 1
INNER JOIN ReceivableDetails ON RID.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive = 1
INNER JOIN Receivables R ON ReceivableDetails.ReceivableId = R.Id
	AND R.IsActive = 1
	AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'))
INNER JOIN Currencies ON
Currencies.Id = RD.CurrencyId
INNER JOIN CurrencyCodes ON
Currencies.CurrencyCodeId = CurrencyCodes.Id
GROUP BY RD.CurrencyId,RD.DueDate,CurrencyCodes.ISO,le.ThresholdDays
)
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
CTE_RID as RID
GROUP BY RID.CurrencyId,RID.ISO
END

GO
