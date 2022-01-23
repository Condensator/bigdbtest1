SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPayableDetailsForAPPayment]
(
@payableIds nvarchar(max),
@treasuryPayableDetailIds TreasuryPayableDetailIds READONLY,
@payableInvoiceEntityType nvarchar(50),
@payableInvoiceAssetSource nvarchar(50),
@payableOtherCostSource nvarchar(50),
@payablePPCAssetSource nvarchar(50),
@inactiveLeaseFinanceStatus nvarchar(50),
@inactiveloanFinanceStatus nvarchar(50),
@progressLoanContractType nvarchar(50),
@loanContractType nvarchar(50),
@leaseContractType nvarchar(50),
@unallocatioedRefundEntityType nvarchar(50),
@sundryPayableSourceType nvarchar(50),
@paymentVoucherIds nvarchar(max),
@PPTInvoiceEntityType nvarchar(50),
@receiptTableType nvarchar(50),
@progressPaymentCreditType nvarchar(50),
@specificCostAdjustmentType NVARCHAR(50),
@CPIReceivablePayableSourceType NVARCHAR(50),
@CPUPayableSourceType NVARCHAR(24),
@CPUReceivableSourceType NVARCHAR(20),
@CPUContractStatusCommenced NVARCHAR(9),
@CPUContractStatusPaidoff NVARCHAR(7),
@ReceivableContractEntityType NVARCHAR(2),
@sundryRecurringPaymentScheduleSourceType NVARCHAR(20)
)
AS
SET NOCOUNT ON
SELECT * INTO #PayableIds FROM ConvertCSVToBigIntTable(@payableIds, ',');
SELECT P.Id 'PayableId', PT.Name 'PayableType', V.Id 'VendorId', P.SourceId 'SourceId', P.SourceTable 'SourceTable', P.EntityType 'EntityType', P.EntityId 'EntityId',
P.Amount_Amount 'PayableAmount', P.Amount_Currency 'PayableCurrency', P.Balance_Amount 'PayableBalance', P.RemitToId 'PayableRemitToId', P.DueDate 'PayableDueDate', V.IsIntercompany
INTO #PayableTemp
FROM #PayableIds
JOIN Payables P ON P.Id = #PayableIds.Id
JOIN PayableCodes PC ON P.PayableCodeId = PC.Id
JOIN PayableTypes PT ON PC.PayableTypeId = PT.Id
JOIN Parties V ON P.PayeeId = V.Id
;
--PIA
SELECT PayableId,SourceId, SourceTable,PayableInvoiceId,UsePayDate,ContractType,LoanFinanceId,LeaseFinanceId,AssetId
,LineofBusinessId,InstrumentTypeId, PayableInvoiceOtherCostId, CostCenterId, IsIntercompany, DiscountingId
INTO #LeaseAssetTemp
FROM
(
Select P.PayableId, P.SourceId, P.SourceTable,PI.Id as PayableInvoiceId,LA.UsePayDate as UsePayDate,C.ContractType as ContractType,null as LoanFinanceId,LF.Id as LeaseFinanceId
,A.Id as AssetId,Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.LineofBusinessId Else C.LineofBusinessId End as LineofBusinessId,Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.InstrumentTypeId Else LF.InstrumentTypeId End as InstrumentTypeId, null as PayableInvoiceOtherCostId, Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.CostCenterId Else LF.CostCenterId End as CostCenterId, P.IsIntercompany,ROW_NUMBER() OVER (PARTITION BY P.PayableId ORDER BY LF.IsCurrent DESC, LF.Id DESC) AS RowNumber, NULL as DiscountingId
FROM #PayableTemp P
JOIN PayableInvoiceAssets PIA ON P.SourceId = PIA.Id 
AND P.SourceTable = @payableInvoiceAssetSource 
AND P.EntityId = PIA.PayableInvoiceId
AND P.EntityType = @payableInvoiceEntityType
JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id
LEFT JOIN LeaseAssets LA ON LA.AssetId = PIA.AssetId AND (LA.PayableInvoiceId IS NULL OR PI.Id = LA.PayableInvoiceId) AND LA.IsActive = 1
LEFT JOIN Assets A ON LA.AssetId = A.Id
LEFT JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id
LEFT JOIN Contracts C ON LF.ContractId = C.Id
LEFT JOIN LeaseFundings FU ON LF.Id = FU.LeaseFinanceId
LEFT JOIN AssetValueHistories AVH ON A.Id = AVH.AssetId
WHERE LA.Id IS NULL OR (LF.ApprovalStatus != @inactiveLeaseFinanceStatus
AND AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1
AND AVH.IsCleared = 1
AND (PI.ParentPayableInvoiceId IS NULL
OR LF.IsCurrent = 1)))
AS LeaseAssetInfo
WHERE LeaseAssetInfo.RowNumber = 1
--PIOC
Select P.PayableId, P.SourceId, P.SourceTable,PI.Id as PayableInvoiceId,FU.UsePayDate as UsePayDate,C.ContractType as ContractType,LF.Id as LoanFinanceId,null as LeaseFinanceId,null as AssetId,
--Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.LineofBusinessId Else C.LineofBusinessId End as LineofBusinessId,
(CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.LineofBusinessId WHEN LF.LineofBusinessId IS NOT NULL THEN LF.LineofBusinessId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.LineofBusinessId ELSE Null END) as LineofBusinessId,
(CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.InstrumentTypeId WHEN LF.InstrumentTypeId IS NOT NULL THEN LF.InstrumentTypeId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.InstrumentTypeId ELSE Null END) as InstrumentTypeId,
PIOC.Id as PayableInvoiceOtherCostId,
--Case When (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) Then PI.CostCenterId Else LF.CostCenterId End as CostCenterId,
(CASE WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.CostCenterId WHEN LF.CostCenterId IS NOT NULL THEN LF.CostCenterId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.CostCenterId ELSE Null END) as CostCenterId,
P.IsIntercompany, NULL as DiscountingId
INTO #LoanOtherCostTemp
FROM #PayableTemp P
JOIN PayableInvoiceOtherCosts PIOC ON  P.SourceId = PIOC.Id
AND P.SourceTable = @payableOtherCostSource
AND P.EntityId = PIOC.PayableInvoiceId AND P.EntityType = @payableInvoiceEntityType 
JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id
AND (PI.ContractType = @loanContractType OR PI.ContractType = @progressLoanContractType)
LEFT JOIN LoanFundings FU ON FU.FundingId = PIOC.PayableInvoiceId AND FU.IsActive = 1
LEFT JOIN LoanFinances LF ON FU.LoanFinanceId = LF.Id
LEFT JOIN Contracts C ON LF.ContractId = C.Id
LEFT JOIN PayableInvoiceOtherCosts ProgressFunding ON PIOC.ProgressFundingId = ProgressFunding.Id AND PIOC.AllocationMethod = ''' + @progressPaymentCreditType +'''
LEFT JOIN LoanFundings ProgressLoanFunding ON ProgressFunding.PayableInvoiceId = ProgressLoanFunding.FundingId
LEFT JOIN LoanFinances ProgressLoan ON ProgressLoanFunding.LoanFinanceId = ProgressLoan.Id

--PIOC of lease
Select P.PayableId, P.SourceId, P.SourceTable,PI.Id as PayableInvoiceId,FU.UsePayDate as UsePayDate,ISNULL(LSCA.ContractType,C.ContractType) as ContractType,null as LoanFinanceId, ISNULL(LSCA.LeaseFinanceId,LF.Id) as LeaseFinanceId,A.Id as AssetId,CASE WHEN AGL.LineofBusinessId IS NOT NUll THEN AGL.LineofBusinessId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.LineofBusinessId  WHEN LSCA.LineofBusinessId IS NOT NULL THEN LSCA.LineofBusinessId ELSE C.LineofBusinessId END as LineofBusinessId,(CASE WHEN AGL.InstrumentTypeId IS NOT NUll THEN AGL.InstrumentTypeId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null)  THEN PI.InstrumentTypeId  WHEN ProgressLoan.Id IS NOT NULL THEN ProgressLoan.InstrumentTypeId WHEN LSCA.PayableInvoiceOtherCostId IS NOT NULL THEN LSCA.InstrumentTypeId ELSE LF.InstrumentTypeId END) as InstrumentTypeId, PIOC.Id as PayableInvoiceOtherCostId,CASE WHEN AGL.CostCenterId IS NOT NUll THEN AGL.CostCenterId WHEN (PI.InstrumentTypeId Is Not Null and PI.LineofBusinessId Is Not Null and PI.CostCenterId Is Not Null) THEN PI.CostCenterId  WHEN LSCA.CostCenterId IS NOT NULL THEN LSCA.CostCenterId ELSE LF.CostCenterId END as CostCenterId, P.IsIntercompany, NULL as DiscountingId
INTO #LeaseOtherCostTemp
FROM #PayableTemp P
JOIN PayableInvoiceOtherCosts PIOC ON P.SourceId = PIOC.Id
AND P.SourceTable = @payableOtherCostSource 
AND P.EntityId = PIOC.PayableInvoiceId
AND P.EntityType = @payableInvoiceEntityType
JOIN PayableInvoices PI ON PIOC.PayableInvoiceId = PI.Id
AND PI.ContractType = @leaseContractType
LEFT JOIN LeaseFundings FU ON FU.FundingId = PIOC.PayableInvoiceId AND FU.IsActive = 1
LEFT JOIN LeaseFinances LF ON FU.LeaseFinanceId = LF.Id
LEFT JOIN Contracts C ON LF.ContractId = C.Id
LEFT JOIN PayableInvoiceOtherCosts ProgressFunding ON PIOC.ProgressFundingId = ProgressFunding.Id AND PIOC.AllocationMethod = ''' + @progressPaymentCreditType +'''
LEFT JOIN LoanFundings ProgressLoanFunding ON ProgressFunding.PayableInvoiceId = ProgressLoanFunding.FundingId
LEFT JOIN LoanFinances ProgressLoan ON ProgressLoanFunding.LoanFinanceId = ProgressLoan.Id
LEFT JOIN (SELECT PayableId, PayableInvoiceOtherCosts.Id PayableInvoiceOtherCostId, LeaseFinances.Id LeaseFinanceId, Contracts.ContractType, LeaseFinances.InstrumentTypeId, LeaseFinances.CostCenterId, Contracts.LineofBusinessId, Contracts.Id ContractId, Contracts.SequenceNumber, LeaseFinances.IsCurrent, ROW_NUMBER() OVER(PARTITION BY #PayableTemp.PayableId ORDER BY LeaseFinances.IsCurrent DESC,LeaseFinances.Id DESC) RowNumber
FROM #PayableTemp
JOIN PayableInvoiceOtherCosts ON #PayableTemp.SourceTable = @payableOtherCostSource  AND #PayableTemp.SourceId = PayableInvoiceOtherCosts.Id AND PayableInvoiceOtherCosts.AllocationMethod = @specificCostAdjustmentType  AND PayableInvoiceOtherCosts.IsActive=1
JOIN LeaseSpecificCostAdjustments ON PayableInvoiceOtherCosts.Id = LeaseSpecificCostAdjustments.PayableInvoiceOtherCostId AND LeaseSpecificCostAdjustments.IsActive=1
JOIN LeaseFinances ON LeaseSpecificCostAdjustments.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.BookingStatus <> 'Inactive'
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id) AS LSCA ON P.PayableId = LSCA.PayableId AND LSCA.RowNumber=1
LEFT JOIN Assets A ON PIOC.AssetId = A.Id
LEFT JOIN AssetGLDetails AGL ON A.Id = AGL.Id
AND PIOC.AllocationMethod = @specificCostAdjustmentType;
;
--Sundry
Select
PayableId, SourceId, SourceTable,PayableInvoiceId,UsePayDate,ContractType,LoanFinanceId,LeaseFinanceId
,AssetId,LineofBusinessId,InstrumentTypeId,PayableInvoiceOtherCostId,CostCenterId,IsIntercompany,DiscountingId INTO #SundryTemp
FROM (
Select
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,C.ContractType as ContractType,LOF.Id as LoanFinanceId,LEF.Id as LeaseFinanceId
,null as AssetId,S.LineofBusinessId as LineofBusinessId,S.InstrumentTypeId as InstrumentTypeId, null as PayableInvoiceOtherCostId, S.CostCenterId as CostCenterId, P.IsIntercompany, D.Id as DiscountingId 
FROM #PayableTemp P
JOIN Sundries S ON P.PayableId = S.PayableId
LEFT JOIN Contracts C ON S.ContractId = C.Id
LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
LEFT JOIN DiscountingSundries DS ON S.Id = DS.Id
LEFT JOIN Discountings D on DS.DiscountingId = D.Id
UNION ALL
Select
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,C.ContractType as ContractType,LOF.Id as LoanFinanceId,LEF.Id as LeaseFinanceId
,null as AssetId,S.LineofBusinessId as LineofBusinessId,S.InstrumentTypeId as InstrumentTypeId, null as PayableInvoiceOtherCostId, S.CostCenterId as CostCenterId, P.IsIntercompany, D.Id as DiscountingId 
FROM #PayableTemp P
JOIN Sundries S ON P.SourceTable = @sundryPayableSourceType AND P.SourceId = S.Id AND ( S.PayableId IS NULL OR P.PayableId <> S.PayableId )
LEFT JOIN Contracts C ON S.ContractId = C.Id
LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
LEFT JOIN DiscountingSundries DS ON S.Id = DS.Id
LEFT JOIN Discountings D on DS.DiscountingId = D.Id
) List
--Sundry recurring
SELECT 
PayableId, SourceId, SourceTable,PayableInvoiceId,UsePayDate,ContractType,LoanFinanceId,LeaseFinanceId
,AssetId,LineofBusinessId,InstrumentTypeId, PayableInvoiceOtherCostId, CostCenterId, IsIntercompany, DiscountingId
INTO #SundryRecurringTemp
from 
(SELECT 
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,C.ContractType as ContractType,LOF.Id as LoanFinanceId,LEF.Id as LeaseFinanceId
,null as AssetId,S.LineofBusinessId as LineofBusinessId,S.InstrumentTypeId as InstrumentTypeId, null as PayableInvoiceOtherCostId, S.CostCenterId as CostCenterId, P.IsIntercompany, NULL as DiscountingId


FROM #PayableTemp P
JOIN SundryRecurringPaymentSchedules SPS ON (P.PayableId = SPS.PayableId)
JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id
JOIN Parties CU ON S.CustomerId = CU.Id
LEFT JOIN Contracts C ON S.ContractId = C.Id
LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
union all
SELECT 
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,C.ContractType as ContractType,LOF.Id as LoanFinanceId,LEF.Id as LeaseFinanceId
,NULL as AssetId,S.LineofBusinessId as LineofBusinessId,S.InstrumentTypeId as InstrumentTypeId, NULL as PayableInvoiceOtherCostId, S.CostCenterId as CostCenterId, P.IsIntercompany, NULL as DiscountingId

FROM #PayableTemp P
JOIN SundryRecurringPaymentSchedules SPS ON (P.SourceTable = @sundryRecurringPaymentScheduleSourceType AND P.SourceId = SPS.Id) AND ( SPS.PayableId is NULL OR P.PayableId <> SPS.PayableId)
JOIN SundryRecurrings S ON SPS.SundryRecurringId = S.Id
JOIN Parties CU ON S.CustomerId = CU.Id
LEFT JOIN Contracts C ON S.ContractId = C.Id
LEFT JOIN LoanFinances LOF ON S.ContractId = LOF.ContractId AND LOF.IsCurrent = 1
LEFT JOIN LeaseFinances LEF ON S.ContractId = LEF.ContractId AND LEF.IsCurrent = 1
)list;
--UnallocatedRefund
SELECT
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,'_' as ContractType,null as LoanFinanceId,null as LeaseFinanceId
,null as AssetId,UR.LineofBusinessId as LineofBusinessId,UR.InstrumentTypeId as InstrumentTypeId, null as PayableInvoiceOtherCostId, R.CostCenterId as CostCenterId, P.IsIntercompany, NULL as DiscountingId
INTO #CashRefundTemp
FROM #PayableTemp P
JOIN UnallocatedRefunds UR ON P.EntityId = UR.Id AND P.EntityType = @unallocatioedRefundEntityType
JOIN UnallocatedRefundDetails URD ON UR.Id = URD.UnallocatedRefundId
JOIN Receipts R ON P.SourceId = R.Id AND P.SourceTable = @receiptTableType
;
-- Property Tax Invoice
SELECT
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,'_' as ContractType,null as LoanFinanceId,null as LeaseFinanceId
,null as AssetId,PPTI.LineofBusinessId as LineofBusinessId,NULL as InstrumentTypeId, null as PayableInvoiceOtherCostId, PPTI.CostCenterId as CostCenterId, P.IsIntercompany, NULL as DiscountingId
INTO #PropertyTaxInvoiceTemp
FROM #PayableTemp P
JOIN PPTInvoices PPTI ON  P.EntityId = PPTI.Id AND P.EntityType = @PPTInvoiceEntityType 
;

--CPI Receivables
Select
P.PayableId, P.SourceId, P.SourceTable,null as PayableInvoiceId,CONVERT(BIT, 0) as UsePayDate,C.ContractType as ContractType,
NULL as LoanFinanceId,LEF.Id as LeaseFinanceId,null as AssetId ,
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.LineofBusinessId ELSE CPUA.LineofBusinessId END)  as LineofBusinessId,
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.InstrumentTypeId ELSE CPUA.InstrumentTypeId END)  as InstrumentTypeId,
null as PayableInvoiceOtherCostId,
(CASE WHEN R.EntityType = @ReceivableContractEntityType THEN LEF.CostCenterId ELSE CPUA.CostCenterId  END) as CostCenterId,
P.IsIntercompany, NULL as DiscountingId
INTO #CPUTemp
FROM #PayableTemp P
JOIN Receivables R ON P.SourceId = R.Id AND P.SourceTable = @CPUPayableSourceType
JOIN CPUSchedules CPUS ON CPUS.Id = R.SourceId AND R.SourceTable = @CPUReceivableSourceType
JOIN CPUFinances CPUF ON CPUS.CPUFinanceId = CPUF.Id
JOIN CPUAccountings CPUA ON CPUF.Id = CPUA.Id
JOIN CPUTransactions CPUT ON CPUT.CPUFinanceId = CPUF.Id
JOIN CPUContracts CPUC ON CPUC.Id = CPUT.CPUContractId
AND (
CPUC.Status = @CPUContractStatusCommenced
OR CPUC.Status = @CPUContractStatusPaidoff
)
LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @ReceivableContractEntityType
LEFT JOIN LeaseFinances LEF ON C.Id = LEF.ContractId AND LEF.IsCurrent = 1;
SELECT *
INTO  #temp_UNION
FROM
(
select * from #LeaseAssetTemp
union
select * from #LoanOtherCostTemp
union
select * from #LeaseOtherCostTemp
union
select * from #SundryTemp
union
select * from #SundryRecurringTemp
union
select * from #CashRefundTemp
union
select * from #PropertyTaxInvoiceTemp
union
select * from #CPUTemp
) union_alias
SELECT
PaymentVouchers.Id as PaymentVoucherId,
PaymentVouchers.PaymentDate as RequestedPaymentDate,
TreasuryPayables.Id as TreasuryPayableId,
DRP.Id as DisbursementRequestPayableId,
(CASE WHEN DR.Id IS NULL THEN PCC.ISO ELSE DRCC.ISO END) as ContractCurrencyCode,
#temp_UNION.PayableInvoiceId as PayableInvoiceId,
Payables.Id as PayableId,
#temp_UNION.PayableInvoiceOtherCostId as PayableInvoiceOtherCostId,
PayableTypes.Name as PayableType,
PayableCodes.GLTemplateId as GLTemplateId,
#temp_UNION.CostCenterId as CostCenterId,
CASE WHEN PaymentVoucherDetails.Amount_Amount IS NULL
THEN 0.0
ELSE PaymentVoucherDetails.Amount_Amount  end as PaymentVoucherDetailAmount_Amount,
CASE WHEN PaymentVoucherDetails.Amount_Currency IS NULL
THEN 'USD'
ELSE PaymentVoucherDetails.Amount_Currency END as PaymentVoucherDetailAmount_Currency,
CASE WHEN PaymentVoucherDetails.ReceivableOffsetAmount_Amount IS NULL
THEN 0.0
ELSE PaymentVoucherDetails.ReceivableOffsetAmount_Amount END as ReceivableOffsetAmount_Amount,
CASE WHEN PaymentVoucherDetails.ReceivableOffsetAmount_Currency IS NULL
THEN 'USD'
ELSE PaymentVoucherDetails.ReceivableOffsetAmount_Currency END as ReceivableOffsetAmount_Currency,
#temp_UNION.UsePayDate as UsePayDate,
#temp_UNION.ContractType as ContractType,
#temp_UNION.LoanFinanceId as LoanFinanceId,
#temp_UNION.LeaseFinanceId as LeaseFinanceId,
#temp_UNION.AssetId as AssetId,
#temp_UNION.LineofBusinessId as LineofBusinessId,
#temp_UNION.InstrumentTypeId as InstrumentTypeId,
payableCurrency.Id as PayableCurrency,
#temp_UNION.IsIntercompany as IsIntercompany,
#temp_UNION.DiscountingId as DiscountingId
into #Result
from payables
join #temp_UNION on Payables.Id = #temp_UNION.PayableId
left join PayableCodes on Payables.PayableCodeId = PayableCodes.Id
left join PayableTypes on PayableCodes.PayableTypeId = PayableTypes.Id
left join Currencies payableCurrency on Payables.CurrencyId = payableCurrency.Id
left join CurrencyCodes PCC on payableCurrency.CurrencyCodeId = PCC.Id
left JOIN TreasuryPayableDetails ON Payables.Id=TreasuryPayableDetails.PayableId AND TreasuryPayableDetails.IsActive = 1
left JOIN TreasuryPayables ON TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.Id
left JOIN PaymentVoucherDetails ON TreasuryPayables.Id =PaymentVoucherDetails.TreasuryPayableId
left join PaymentVouchers on PaymentVoucherDetails.PaymentVoucherId = PaymentVouchers.Id
left join DisbursementRequestPayables DRP on TreasuryPayableDetails.DisbursementRequestPayableId = DRP.Id and DRP.IsActive = 1
left join disbursementrequests DR on DRP.DisbursementRequestId = DR.Id
left join Currencies DRCurrency on DR.ContractCurrencyId = DRCurrency.Id
left join CurrencyCodes DRCC on DRCurrency.CurrencyCodeId = DRCC.Id
left join @treasuryPayableDetailIds TPD on TreasuryPayableDetails.Id = TPD.Id
Where (@paymentVoucherIds = '' or PaymentVouchers.Id IN (SELECT Id FROM ConvertCSVToBigIntTable(@paymentVoucherIds, ',')))
and (TreasuryPayables.Id is null or (TreasuryPayables.Status!='Inactive' AND TPD.Id IS NOT NULL));
SELECT
PaymentVoucherId,
RequestedPaymentDate,
TreasuryPayableId,
DisbursementRequestPayableId,
ContractCurrencyCode,
PayableInvoiceId,
PayableId,PayableInvoiceOtherCostId,
PayableType,
GLTemplateId,
#Result.CostCenterId,
PaymentVoucherDetailAmount_Amount,
PaymentVoucherDetailAmount_Currency,
ReceivableOffsetAmount_Amount,
ReceivableOffsetAmount_Currency,
UsePayDate,
#Result.ContractType,
LoanFinanceId,
LeaseFinanceId,
AssetId,
#Result.LineofBusinessId,
#Result.InstrumentTypeId,
PayableCurrency,
(CASE
When PayableInvoiceContracts.Id is NOT NULL THEN PayableInvoiceContracts.Id
ELSE Contracts.Id
END) AS ContractId,
(CASE
When PayableInvoiceContracts.Id is NOT NULL THEN PayableInvoiceContracts.SequenceNumber
ELSE Contracts.SequenceNumber
END) AS ContractSequenceNumber,
IsIntercompany,
DiscountingId
FROM #Result
JOIN Payables ON #Result.PayableId = Payables.Id
LEFT JOIN PayableInvoices ON Payables.EntityId = PayableInvoices.Id AND Payables.EntityType = 'PI'
LEFT JOIN Contracts PayableInvoiceContracts ON PayableInvoices.ContractId = PayableInvoiceContracts.Id
LEFT JOIN Contracts Contracts ON Payables.EntityId = Contracts.Id AND Payables.EntityType = 'CT'
LEFT JOIN Discountings Discountings ON Payables.EntityId = Discountings.Id AND Payables.EntityType='DT'
SET NOCOUNT OFF;

GO
