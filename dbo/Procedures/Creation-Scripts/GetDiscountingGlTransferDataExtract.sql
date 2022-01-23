SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingGlTransferDataExtract]
@DiscountingIds DiscountingIdCollection READONLY,
@EffectiveDate DATE
AS
BEGIN
SET NOCOUNT ON;
-- Blended info --
select blendedItemDetail.Id  as BlendedItemDetailId
,discountingFinance.DiscountingId
,blendedItem.Id as BlendedItemId
,receivable.Id as ReceivableId
,payable.Id as PayableId
,blendedItemDetail.DueDate
,blendedItem.Type as BlendedItemType
,blendedItem.BookRecognitionMode
,blendedItem.Occurrence
,blendedItem.BookingGLTemplateId
,blendedItem.Name
,blendedItemDetail.Amount_Amount as BlendedItemDetailIAmount
,blendedItem.Amount_Amount as BlendedItemAmount
,case when blendedItem.Type ='Income' then receivableCode.GLTemplateId else payableCode.GLTemplateId end as CodeGLTemplateId
, blendedItem.GeneratePayableOrReceivable
,receivable.TotalBalance_Amount as ReceivableTotalBalanceAmount
,receivable.TotalAmount_Amount as ReceivableTotalAmount
,payable.Balance_Amount  as PayableBalanceAmount
,payable.Amount_Amount  as PayableAmount
,receivable.IsGLPosted  as IsReceivableGLPosted
,payable.IsGLPosted  as IsPayableGLPosted
,ReceivableTaxes.IsGLPosted as IsReceivableTaxGLPosted
,ReceivableTaxes.Id as ReceivableTaxId
,ReceivableTaxes.GLTemplateId as ReceivableTaxGLTemplateId
,ReceivableTaxes.Amount_Amount as ReceivableTaxAmount
,ReceivableTaxes.Balance_Amount as ReceivableTaxBalance
,prepaidReceivable.PrePaidAmount_Amount as PrePaidReceivableAmount
,prepaidReceivable.PrePaidTaxAmount_Amount as PrePaidReceivableTaxAmount
,LegalEntities.TaxRemittancePreference as TaxRemittancePreference
,blendedItemDetail.DueDate as blendedItemDetailDueDate
,receivable.DueDate as receivableDueDate
,payable.DueDate as payableDueDate
,receivableCode.Name as ReceivableCode
,blendedItem.SystemConfigType
from DiscountingBlendedItems discountingBlendedItem
JOIN DiscountingFinances discountingFinance on discountingBlendedItem.DiscountingFinanceId = discountingFinance.Id AND discountingFinance.IsCurrent=1
JOIN @DiscountingIds DiscountingId on discountingFinance.DiscountingId = DiscountingId.DiscountingId
JOIN BlendedItems blendedItem on discountingBlendedItem.BlendedItemId = blendedItem.Id AND blendedItem.IsActive =1
JOIN BlendedItemDetails blendedItemDetail on blendedItem.Id = blendedItemDetail.BlendedItemId AND blendedItemDetail.IsActive=1
LEFT JOIN PayableCodes payableCode on blendedItem.PayableCodeId = payableCode.Id
LEFT JOIN ReceivableCodes receivableCode on blendedItem.ReceivableCodeId = receivableCode.Id
LEFT JOIN Sundries sundry on blendedItemDetail.SundryId = sundry.Id AND  sundry.entitytype='DT'
LEFT JOIN Receivables receivable on sundry.ReceivableId = receivable.Id and receivable.EntityType='DT'
LEFT JOIN LegalEntities ON receivable.LegalEntityId = LegalEntities.Id
LEFT JOIN ReceivableTaxes ON receivable.Id = ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
LEFT JOIN PrepaidReceivables prepaidReceivable on receivable.Id = prepaidReceivable.ReceivableId and prepaidReceivable.IsActive=1
LEFT JOIN Payables payable on sundry.PayableId = payable.Id AND payable.EntityType = 'DT' and payable.Status ='Approved'
where blendedItemDetail.IsGLPosted = 1
--(ISNULL(ISNULL(receivable.DueDate,payable.DueDate),blendedItemDetail.DueDate) < @EffectiveDate) AND blendedItemDetail.IsGLPosted = 1
--Capitalized Interest Info--
select discountingCapitalizedInterest.Id as DiscountingCapitalizedInterestId
,discountingFinance.DiscountingId
,discountingCapitalizedInterest.Amount_Amount  as Amount
,discountingCapitalizedInterest.CapitalizedDate
from DiscountingCapitalizedInterests discountingCapitalizedInterest
JOIN DiscountingFinances discountingFinance on discountingCapitalizedInterest.DiscountingFinanceId = discountingFinance.Id AND discountingFinance.IsCurrent=1
JOIN @DiscountingIds DiscountingId on discountingFinance.DiscountingId = DiscountingId.DiscountingId
where discountingCapitalizedInterest.IsActive=1 AND discountingCapitalizedInterest.GLJournalId IS NOT NULL
--and discountingCapitalizedInterest.CapitalizedDate < @EffectiveDate
-- Discounting Amort Schedule--
SELECT D.DiscountingId
,MAX(discountingAmortSchedule.ExpenseDate) ExpenseDate
INTO #MaxExpenseGLPostedDate
FROM @DiscountingIds D
join DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId
JOIN DiscountingAmortizationSchedules discountingAmortSchedule ON discountingAmortSchedule.DiscountingFinanceId = discountingFinance.Id
AND discountingAmortSchedule.IsAccounting=1 AND discountingAmortSchedule.IsGLPosted=1
WHERE discountingAmortSchedule.AdjustmentEntry=0
GROUP BY D.DiscountingId
select discountingAmortSchedule.Id as AmortScheduleId
,discountingFinance.DiscountingId
,discountingAmortSchedule.IsGLPosted
,discountingAmortSchedule.IsNonAccrual
,discountingAmortSchedule.ExpenseDate
,discountingAmortSchedule.InterestAccrued_Amount  as InterestAccruedAmount
,discountingAmortSchedule.AdjustmentEntry
from DiscountingAmortizationSchedules discountingAmortSchedule
JOIN DiscountingFinances discountingFinance on discountingAmortSchedule.DiscountingFinanceId = discountingFinance.Id
JOIN @DiscountingIds Discounting on discountingFinance.DiscountingId = Discounting.DiscountingId
JOIN #MaxExpenseGLPostedDate maxExpenseGLPostedDate on  Discounting.DiscountingId = maxExpenseGLPostedDate.DiscountingId
WHERE discountingAmortSchedule.IsSchedule=1 AND discountingAmortSchedule.ExpenseDate<= maxExpenseGLPostedDate.ExpenseDate
-- Discounting Repayment (Discounting Interest and Principal Payable)(Miscellaneous Payables)--
select discountingFinance.DiscountingId
,disbursementRequestPayable.AmountToPay_Amount  as DisbursementRequestPayableAmount
,payable.Status as PayableStatus
,payableCode.Name  as payableCodeName
,payable.Id as PayableId
,payableCode.GLTemplateId  as PayableCodeGLTemplateId
,payableType.Name as PayableTypeName
,payable.Balance_Amount  as PayableBalanceAmount
,payable.Amount_Amount  as PayableAmount
,payable.DueDate
,treasuryPayable.Balance_Amount  as TreasuryPayableBalanceAmount
,treasuryPayable.Amount_Amount  as TreasuryPayableAmount
from @DiscountingIds D
JOIN DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId
JOIN Payables payable on discountingFinance.DiscountingId = payable.EntityId and payable.EntityType = 'DT' and payable.Status ='Approved'
JOIN PayableCodes payableCode on payable.PayableCodeId = payableCode.Id
JOIN PayableTypes payableType on payableCode.PayableTypeId = payableType.Id
LEFT JOIN Sundries sundry on payable.Id = sundry.PayableId
LEFT JOIN DiscountingSundries discountingSundry on sundry.Id = discountingSundry.Id AND discountingSundry.DiscountingId = discountingFinance.DiscountingId
LEFT JOIN DiscountingRepaymentSchedules discountingRepaymentSchedule on discountingSundry.PaymentScheduleId = discountingRepaymentSchedule.Id
LEFT JOIN DisbursementRequestPayables disbursementRequestPayable on sundry.PayableId = disbursementRequestPayable.PayableId AND disbursementRequestPayable.IsActive=1
LEFT JOIN TreasuryPayableDetails treasuryPayableDetail on disbursementRequestPayable.Id = treasuryPayableDetail.DisbursementRequestPayableId AND treasuryPayableDetail.IsActive=1
LEFT JOIN TreasuryPayables treasuryPayable on treasuryPayableDetail.TreasuryPayableId = treasuryPayable.Id and treasuryPayable.Status = 'Approved'
WHERE ISNULL(discountingRepaymentSchedule.EndDate,payable.DueDate) < @EffectiveDate AND payableType.Name in ('DiscountingPrincipal','DiscountingInterest') and discountingFinance.isCurrent =1
-- Discounting Receivables --
select R.Id as ReceivableId
,discountingFinance.DiscountingId
,R.TotalBalance_Amount as TotalBalanceAmount
,R.TotalAmount_Amount as TotalAmount
,R.IsGLPosted
FROM @DiscountingIds D
JOIN DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId
JOIN Receivables R on discountingFinance.DiscountingId = R.EntityId and R.EntityType='DT'
WHERE R.DueDate < @EffectiveDate AND discountingFinance.DiscountingProceedsReceivableCodeId = R.ReceivableCodeId AND discountingFinance.IsCurrent=1
-- Discounting Servicing Details--
select discountingFinance.DiscountingId
,discountingServicingdetail.Collected
,discountingServicingdetail.Effectivedate  as FromDate
,LEAD(discountingServicingdetail.Effectivedate, 1, NULL) OVER (ORDER BY discountingServicingdetail.Effectivedate) AS ToDate
from @DiscountingIds D
JOIN DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId
JOIN discountingServicingdetails discountingServicingdetail on discountingFinance.id = discountingServicingdetail.discountingFinanceId
where  discountingFinance.IsCurrent = 1 AND discountingServicingdetail.IsActive = 1 AND discountingServicingdetail.Effectivedate < @EffectiveDate
-- Effective Balance and Book Balance
select
discountingFinance.DiscountingId
,EffectivePrincipalBalance_Amount as EffectivePrincipalBalanceAmount
,EffectiveExpenseBalance_Amount as EffectiveExpenseBalanceAmount
,PrincipalBookBalance_Amount as PrincipalBookBalanceAmount
,ExpenseBookBalance_Amount as ExpenseBookBalanceAmount
from @DiscountingIds D
JOIN DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId
JOIN  DiscountingRepaymentSchedules discountingRepaymentSchedule on discountingRepaymentSchedule.DiscountingFinanceId = discountingFinance.Id
where discountingFinance.IsCurrent=1
------Discounting Repayment Schedule Info
SELECT DR.Id,
D.DiscountingId,
PaymentNumber,
DueDate,
StartDate,
EndDate,
Amount_Amount as Amount,
DR.Principal_Amount as PrincipalAmount,
DR.GainLoss_Amount as GainLossAmount
FROM @DiscountingIds D
	JOIN DiscountingFinances discountingFinance on D.DiscountingId =  discountingFinance.DiscountingId    
    JOIN DiscountingRepaymentSchedules DR ON discountingFinance.Id = DR.DiscountingFinanceId
     WHERE discountingFinance.IsCurrent=1 
	 AND DR.IsActive = 1 

------Discounting WriteDown Info

SELECT 
	D.DiscountingId,
	DiscountingWriteDowns.WriteDownGLTemplateId,
	DiscountingWriteDowns.WriteDownDate,
	DiscountingWriteDowns.WriteDownAmount_Amount as WriteDownAmount
FROM @DiscountingIds D 
JOIN DiscountingWriteDowns ON D.DiscountingId = DiscountingWriteDowns.DiscountingId AND DiscountingWriteDowns.Status = 'Approved'

----------------------------------------------------------------------------
IF OBJECT_ID('temp..#MaxExpenseGLPostedDate') IS NOT NULL
DROP TABLE #MaxExpenseGLPostedDate
SET NOCOUNT OFF;
END

GO
