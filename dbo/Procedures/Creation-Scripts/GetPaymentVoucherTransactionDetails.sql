SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPaymentVoucherTransactionDetails]
(
@PaymentVoucherId NVARCHAR(MAX),
@PayableInvoiceAsset NVARCHAR(30),
@PayableInvoiceOtherCost NVARCHAR(30),
@PayableInvoiceCompletedStatus NVARCHAR(15)
)
AS
BEGIN
WITH CTE_PayableDetails
AS
(
SELECT PV.Id AS PaymentVoucherId,P.SourceTable,P.SourceId,PV.VoucherNumber FROM PaymentVouchers PV
JOIN PaymentVoucherDetails PVD ON PV.Id = PVD.PaymentVoucherId
JOIN TreasuryPayables TP ON PVD.TreasuryPayableId = TP.Id
JOIN TreasuryPayableDetails TPD ON TP.Id = TPD.TreasuryPayableId AND TPD.IsActive = 1
JOIN Payables P ON TPD.PayableId = P.Id
WHERE
PV.Id	IN (SELECT Id FROM ConvertCSVToBigIntTable(@PaymentVoucherId,',')) AND
P.SourceTable in(@PayableInvoiceAsset,@PayableInvoiceOtherCost)
),
CTE_AssetFundingDetails
AS
(
SELECT C.*,LFN.UsePayDate,LF.BookingStatus,LA.InterimRentGeneratedTillDate,A.FinancialType,CT.ContractType FROM CTE_PayableDetails C
JOIN PayableInvoiceAssets PIA ON C.SourceId = PIA.Id AND PIA.IsActive = 1
JOIN Assets A ON PIA.AssetId = A.Id
JOIN PayableInvoices PI ON PIA.PayableInvoiceId = PI.Id
LEFT JOIN LeaseFundings LFN ON PI.Id = LFN.FundingId AND LFN.IsActive = 1
LEFT JOIN LeaseFinances LF ON LFN.LeaseFinanceId = LF.Id
LEFT JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND PIA.AssetId = LA.AssetId
LEFT JOIN Contracts CT ON LF.ContractId = CT.Id
WHERE C.SourceTable = @PayableInvoiceAsset
AND CT.ContractType IS NOT NULL
),
CTE_LoanFundingOtherCostDetails
AS
(
SELECT C.*,LFN.UsePayDate,LF.Status,PIO.InterestUpdateLastDate AS InterimRentGeneratedTillDate, NULL AS FinancialType,CT.ContractType FROM CTE_PayableDetails C
JOIN PayableInvoiceOtherCosts PIO ON C.SourceId = PIO.Id AND PIO.IsActive = 1
JOIN PayableInvoices PI ON PIO.PayableInvoiceId = PI.Id
LEFT JOIN LoanFundings LFN ON PI.Id = LFN.FundingId AND LFN.IsActive = 1
LEFT JOIN LoanFinances LF ON LFN.LoanFinanceId = LF.Id
LEFT JOIN Contracts CT ON LF.ContractId = CT.Id
WHERE C.SourceTable = @PayableInvoiceOtherCost
AND CT.ContractType IS NOT NULL
),
CTE_LeaseFundingOtherCostDetails
AS
(
SELECT C.*,LFN.UsePayDate,LF.BookingStatus,PIO.InterestUpdateLastDate AS InterimRentGeneratedTillDate,NULL AS FinancialType,CT.ContractType FROM CTE_PayableDetails C
JOIN PayableInvoiceOtherCosts PIO ON C.SourceId = PIO.Id AND PIO.IsActive = 1
JOIN PayableInvoices PI ON PIO.PayableInvoiceId = PI.Id
LEFT JOIN LeaseFundings LFN ON PI.Id = LFN.FundingId AND LFN.IsActive = 1
LEFT JOIN LeaseFinances LF ON LFN.LeaseFinanceId = LF.Id
LEFT JOIN Contracts CT ON LF.ContractId = CT.Id
WHERE C.SourceTable = @PayableInvoiceOtherCost
AND CT.ContractType IS NOT NULL
),
CTE_Result
AS
(
SELECT * FROM CTE_AssetFundingDetails
UNION
SELECT * FROM CTE_LoanFundingOtherCostDetails
UNION
SELECT * FROM CTE_LeaseFundingOtherCostDetails
)
SELECT PaymentVoucherId,SourceTable,SourceId,UsePayDate,BookingStatus,InterimRentGeneratedTillDate,FinancialType,ContractType,VoucherNumber FROM CTE_Result
END

GO
