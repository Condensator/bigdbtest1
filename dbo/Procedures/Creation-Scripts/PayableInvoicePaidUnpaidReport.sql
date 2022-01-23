SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[PayableInvoicePaidUnpaidReport]
(
@AsOfDate DATE = NULL
)
AS
BEGIN
SET NOCOUNT ON;

SELECT PI.Id PayableInvoiceId,
	ROW_NUMBER() OVER(PARTITION BY PI.InvoiceNumber, PI.VendorId ORDER BY LF.IsCurrent DESC, LOF.IsCurrent DESC) RowNumber
INTO #ValidPayableInvoices
FROM PayableInvoices PI
	LEFT JOIN LeaseFundings LFU ON PI.Id = LFU.FundingId
	LEFT JOIN LeaseFinances LF ON LFU.LeaseFinanceId = LF.Id
	LEFT JOIN LoanFundings LOFU ON PI.Id = LOFU.FundingId
	LEFT JOIN LoanFinances LOF ON LOFU.LoanFinanceId = LOF.Id
WHERE PI.DueDate <= @AsOfDate
	AND PI.Status = 'Completed'

SELECT PI.Id 'PayableInvoiceId'
	,CUS.PartyNumber 'CustomerNumber'
	,CUS.PartyName 'CustomerName'
	,VEN.PartyName 'VendorName'
	,VEN.PartyNumber 'VendorNumber'
	,PI.InvoiceNumber
	,PI.InvoiceDate
	,CS.ISO 'Currency'
	,PI.InitialExchangeRate
	,PI.TotalAssetCost_Amount 'AssetCostAmount'
INTO #PayableInvoiceTemp
FROM PayableInvoices PI
	JOIN #ValidPayableInvoices PIT ON PI.Id = PIT.PayableInvoiceId AND PIT.RowNumber = 1
	JOIN Parties CUS ON PI.CustomerId = CUS.Id
	JOIN Parties VEN ON PI.VendorId = VEN.Id
	JOIN Currencies CC ON PI.CurrencyId = CC.Id
	JOIN CurrencyCodes CS ON CC.CurrencyCodeId = CS.Id
	JOIN Currencies FCC ON PI.ContractCurrencyId = FCC.Id
	JOIN CurrencyCodes FCS ON CC.CurrencyCodeId = FCS.Id;

SELECT PI.PayableInvoiceId 'PayableInvoiceId', SUM(Amount_Amount) 'OtherCostAmount'
INTO #OtherCostAmountTemp
FROM #PayableInvoiceTemp PI
JOIN PayableInvoiceOtherCosts PIOC ON PI.PayableInvoiceId = PIOC.PayableInvoiceId
WHERE PIOC.AllocationMethod <> 'ProgressPaymentCredit'
AND PIOC.IsActive = 1
GROUP BY PI.PayableInvoiceId
;
SELECT PI.PayableInvoiceId 'PayableInvoiceId', SUM(PIOC.Amount_Amount) 'DoNotPayAmount'
INTO #DoNotPayTemp
FROM #PayableInvoiceTemp PI
JOIN PayableInvoiceOtherCosts PIOC ON PI.PayableInvoiceId = PIOC.PayableInvoiceId
WHERE PIOC.AllocationMethod = 'DoNotPay'
AND PIOC.IsActive = 1
GROUP BY PI.PayableInvoiceId
;
SELECT  PI.PayableInvoiceId 'PayableInvoiceId',SUM(Amount_Amount*-1) 'PrePaidAmount'
INTO #PrePaidAmountTemp
FROM
#PayableInvoiceTemp  PI
JOIN PayableInvoiceAssets PIA ON PI.PayableInvoiceId=PIA.PayableInvoiceId
LEFT JOIN PayableInvoiceOtherCosts PIOC ON PI.PayableInvoiceId = PIOC.PayableInvoiceId AND PIOC.AllocationMethod = 'ProgressPaymentCredit' AND PIOC.IsActive = 1
WHERE PIA.IsActive=1 AND(PIOC.Id IS NOT NULL
OR (PIA.Id IS NOT NULL ))
GROUP BY PI.PayableInvoiceId
;
UPDATE #PrePaidAmountTemp
SET PrePaidAmount=PrePaidAmount+PIDTA.TakeDownAmount_Amount
FROM PayableInvoiceDepositTakeDownAssets PIDTA
JOIN PayableInvoiceAssets PIA ON PIA.Id=PIDTA.TakeDownAssetId
WHERE PIA.PayableInvoiceId=#PrePaidAmountTemp.PayableInvoiceId AND PIDTA.IsActive=1
;
SELECT PI.PayableInvoiceId, SUM(DRPS.ApprovedAmount_Amount) 'PaidAmount'
INTO #DomesticInvoicePaidAmount
FROM  #PayableInvoiceTemp PI
JOIN Payables P ON P.EntityId = PI.PayableInvoiceId AND P.EntityType = 'PI'
JOIN DisbursementRequestPayables DRP ON DRP.PayableId = P.Id
JOIN DisbursementRequests DR ON DRP.DisbursementRequestId = DR.Id
JOIN DisbursementRequestPayees DRPS ON DRP.Id = DRPS.DisbursementRequestPayableId
JOIN DisbursementRequestPaymentDetails DRPD ON DRPS.PayeeId = DRPD.Id AND DR.Id = DRPD.DisbursementRequestId
JOIN TreasuryPayableDetails TPD ON P.Id = TPD.PayableId AND DRP.Id = TPD.DisbursementRequestPayableId
JOIN TreasuryPayables TP ON TPD.TreasuryPayableId = TP.Id
JOIN PaymentVoucherDetails PVD ON TP.Id = PVD.TreasuryPayableId
JOIN PaymentVouchers PV ON PVD.PaymentVoucherId = PV.Id
WHERE PV.Status = 'Paid'
AND DRP.IsActive = 1
AND TP.PayeeId = DRPD.PayeeId
AND DR.Status = 'Completed'
GROUP BY PI.PayableInvoiceId;
SELECT
PIT.PayableInvoiceId
, PIT.CustomerNumber
, PIT.CustomerName
, PIT.VendorName
, PIT.VendorNumber
, PIT.InvoiceNumber
, PIT.InvoiceDate
, PIT.InitialExchangeRate
, PIT.Currency
, ISNULL(PIT.AssetCostAmount,0.00) 'AssetCostAmount'
, ISNULL(OCAT.OtherCostAmount,0.00) 'OtherCostAmount'
, (ISNULL(PIT.AssetCostAmount,0.00) + ISNULL(OCAT.OtherCostAmount,0.00)) 'InvoiceTotalAmount'
, ISNULL(PPAT.PrePaidAmount,0.00) 'PrePaidAmount'
, ISNULL(DNPT.DoNotPayAmount,0.00) 'DoNotpayAmount'
, ((ISNULL(PIT.AssetCostAmount,0.00) + ISNULL(OCAT.OtherCostAmount,0.00)) - ISNULL(PPAT.PrePaidAmount,0.00) - ISNULL(DNPT.DoNotPayAmount,0.00)) 'TotalPayableAmount'
, ISNULL(DIA.PaidAmount,0.00) 'PaidAmount'
, (((ISNULL(PIT.AssetCostAmount,0.00) + ISNULL(OCAT.OtherCostAmount,0.00)) - ISNULL(PPAT.PrePaidAmount,0.00) - ISNULL(DNPT.DoNotPayAmount,0.00)) - ISNULL(DIA.PaidAmount,0.00)) 'UnpaidAmount'
FROM #PayableInvoiceTemp PIT
LEFT JOIN #OtherCostAmountTemp OCAT on PIT.PayableInvoiceId = OCAT.PayableInvoiceId
LEFT JOIN #DoNotPayTemp DNPT on PIT.PayableInvoiceId = DNPT.PayableInvoiceId
LEFT JOIN #PrePaidAmountTemp PPAT ON PIT.PayableInvoiceId = PPAT.PayableInvoiceId
LEFT JOIN #DomesticInvoicePaidAmount DIA ON PIT.PayableInvoiceId = DIA.PayableInvoiceId
ORDER BY PIT.InvoiceDate
, PIT.VendorNumber
, PIT.InvoiceNumber
DROP TABLE #PayableInvoiceTemp
DROP TABLE #OtherCostAmountTemp
DROP TABLE #DoNotPayTemp
DROP TABLE #PrePaidAmountTemp
DROP TABLE #DomesticInvoicePaidAmount
DROP TABLE #ValidPayableInvoices
SET NOCOUNT OFF;
END

GO
