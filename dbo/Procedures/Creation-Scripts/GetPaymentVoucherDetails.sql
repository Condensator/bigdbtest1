SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPaymentVoucherDetails]
(@PaymentVoucherIds           NVARCHAR(MAX),
@PayableInvoiceAssetType     NVARCHAR(MAX),
@PayableInvoiceOtherCostType NVARCHAR(MAX),
@SundryType                  NVARCHAR(MAX),
@SundryRecurringType         NVARCHAR(MAX),
@UnallocatedRefundType       NVARCHAR(MAX),
@SyndicatedARType            NVARCHAR(MAX),
@IndirectARType              NVARCHAR(MAX),
@ContractEntityType          NVARCHAR(MAX),
@ReceiptType                 NVARCHAR(MAX),
@CPIReceivableType           NVARCHAR(MAX),
@CPUPayableSourceType		  NVARCHAR(MAX),
@CPUReceivableSourceType	  NVARCHAR(MAX)
)
AS
BEGIN
SELECT Id AS PaymentVoucherId
INTO #PaymentVoucherIds
FROM dbo.ConvertCSVToBigIntTable(@PaymentVoucherIds, ',');
WITH CTE_PaymentVoucherDetails
AS (SELECT DISTINCT
PV.Id AS PaymentVoucherId,
PV.VoucherNumber AS VoucherNumber,
R.Name AS RemitToName,
R.Id AS RemitToId,
PV.ReceiptType AS RemittanceType,
'****' + BA.LastFourDigitAccountNumber AS PayFromAccount,
V.PartyNumber AS PayeeNumber,
V.PartyName AS PayeeName,
LE.LegalEntityNumber AS LegalEntityNumber,
P.SourceTable AS SourceTable,
P.SourceId AS SourceId,
P.EntityId AS EntityId,
P.EntityType AS EntityType
FROM PaymentVouchers AS PV
JOIN #PaymentVoucherIds AS PVId ON PV.Id = PVId.PaymentVoucherId
JOIN PaymentVoucherDetails AS PVD ON PV.Id = PVD.PaymentVoucherId
JOIN RemitToes AS R ON PV.RemitToId = R.Id
JOIN TreasuryPayables AS TP ON PVD.TreasuryPayableId = TP.Id
JOIN Parties AS V ON TP.PayeeId = V.Id
JOIN TreasuryPayableDetails AS TPD ON TP.Id = TPD.TreasuryPayableId
AND TPD.IsActive = 1
JOIN Payables AS P ON TPD.PayableId = P.Id
LEFT JOIN BankAccounts AS BA ON PV.PayFromAccountId = BA.Id
JOIN LegalEntities AS LE ON P.LegalEntityId = LE.Id),
CTE_PayableInvocieAssetPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
pv.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN PayableInvoiceAssets AS PIA ON PV.SourceTable = @PayableInvoiceAssetType
AND PV.SourceId = PIA.Id
JOIN PayableInvoices AS PI ON PIA.PayableInvoiceId = PI.Id
JOIN Currencies AS C ON PI.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_PayableInvocieOtherCostPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN PayableInvoiceOtherCosts AS PIO ON PV.SourceTable = @PayableInvoiceOtherCostType
AND PV.SourceId = PIO.Id
JOIN PayableInvoices AS PI ON PIO.PayableInvoiceId = PI.Id
JOIN Currencies AS C ON PI.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_SundryPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN Sundries AS S ON PV.SourceTable = @SundryType
AND PV.SourceId = S.Id
JOIN Currencies AS C ON S.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_SundryRecurringPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN SundryRecurringPaymentSchedules AS SRPS ON PV.SourceId = SRPS.Id
AND SRPS.IsActive = 1
JOIN SundryRecurrings AS SR ON SRPS.SundryRecurringId = SR.Id
AND PV.SourceTable = @SundryRecurringType
JOIN Currencies AS C ON SR.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_UnAllocatedRefundPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN UnallocatedRefunds AS UR ON PV.SourceId = UR.Id
AND PV.SourceTable = @UnallocatedRefundType
JOIN Currencies AS C ON UR.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_SyndicatedContractPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN Contracts AS CT ON PV.EntityId = CT.Id
AND PV.EntityType = @ContractEntityType
AND ( PV.SourceTable = @SyndicatedARType OR PV.SourceTable = @IndirectARType)
JOIN Currencies AS C ON CT.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_ReceiptPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN Receipts AS RC ON PV.SourceId = RC.Id
AND PV.SourceTable = @ReceiptType
JOIN Currencies AS C ON RC.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_CPIPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN CPIReceivables AS CPIR ON PV.SourceId = CPIR.Id
AND PV.SourceTable = @CPIReceivableType
JOIN CPISchedules AS CPIS ON CPIR.CPIScheduleId = CPIS.Id
JOIN CPIContracts AS CPIC ON CPIS.CPIContractId = CPIC.Id
JOIN Currencies AS C ON CPIC.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_CPUPaymentVoucher
AS (SELECT PV.PaymentVoucherId,
PV.VoucherNumber,
PV.RemitToName,
PV.RemitToId,
PV.RemittanceType,
PV.PayFromAccount,
PV.PayeeNumber,
PV.PayeeName,
PV.LegalEntityNumber,
CC.ISO AS CurrencyISO
FROM CTE_PaymentVoucherDetails AS PV
JOIN Receivables AS R ON PV.SourceId = R.Id
AND PV.SourceTable = @CPUPayableSourceType
JOIN CPUSchedules AS CPUS ON R.SourceId = CPUS.Id AND R.SourceTable = @CPUReceivableSourceType
JOIN CPUFinances AS CPUF ON CPUS.CPUFinanceId = CPUF.Id
JOIN Currencies AS C ON CPUF.CurrencyId = C.Id
JOIN CurrencyCodes AS CC ON C.CurrencyCodeId = CC.Id),
CTE_PaymentVouchers
AS (SELECT * FROM CTE_PayableInvocieAssetPaymentVoucher
UNION ALL
SELECT * FROM CTE_PayableInvocieOtherCostPaymentVoucher
UNION ALL
SELECT * FROM CTE_SundryPaymentVoucher
UNION ALL
SELECT * FROM CTE_SundryRecurringPaymentVoucher
UNION ALL
SELECT * FROM CTE_UnAllocatedRefundPaymentVoucher
UNION ALL
SELECT * FROM CTE_SyndicatedContractPaymentVoucher
UNION ALL
SELECT * FROM CTE_ReceiptPaymentVoucher
UNION ALL
SELECT * FROM CTE_CPIPaymentVoucher
UNION ALL
SELECT * FROM CTE_CPUPaymentVoucher)
SELECT DISTINCT * FROM CTE_PaymentVouchers;
END;

GO
