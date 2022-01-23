SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPaymentVoucherReceivableOffsetReceivableAmountDetails]
(
@PaymentVoucherId BigInt
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_ReceivableIds
AS
(
SELECT
R.Id AS ReceivableId
FROM PaymentVoucherReceivableOffsets PVRO
JOIN AccountsPayableReceivables APR
ON PVRO.ReceivableId = APR.Id AND APR.IsActive = 1
JOIN Receivables R
ON APR.ReceivableId = R.Id AND R.IsActive = 1
WHERE PVRO.PaymentVoucherId = @PaymentVoucherId
),
CTE_ReceivableAmountDetails
AS
(
SELECT
R.Id AS ReceivableId,
SUM(RD.Amount_Amount) AS ReceivableAmount_Amount,
(SELECT TOP(1) Amount_Currency FROM ReceivableDetails WHERE ReceivableDetails.IsActive = 1 AND ReceivableDetails.ReceivableId = R.Id) AS ReceivableAmount_Currency,
SUM(RD.Balance_Amount) AS ReceivableBalance_Amount,
(SELECT TOP(1) Amount_Currency FROM ReceivableDetails WHERE ReceivableDetails.IsActive = 1 AND ReceivableDetails.ReceivableId = R.Id) AS ReceivableBalance_Currency,
SUM(RD.EffectiveBalance_Amount) AS ReceivableEffectiveBalance_Amount,
(SELECT TOP(1) Amount_Currency FROM ReceivableDetails WHERE ReceivableDetails.IsActive = 1 AND ReceivableDetails.ReceivableId = R.Id) AS ReceivableEffectiveBalance_Currency
FROM Receivables R
JOIN CTE_ReceivableIds
ON R.Id = CTE_ReceivableIds.ReceivableId AND R.IsActive = 1
JOIN ReceivableDetails RD
ON R.Id = RD.ReceivableId AND RD.IsActive = 1
GROUP BY R.Id
),
CTE_ReceivableApplicationInOtherVouchers
AS
(
SELECT
R.Id AS ReceivableId,
SUM(PVRO.AmountToApply_Amount) AS ReceivableAmountApplied_Amount,
(SELECT TOP(1) AmountToApply_Currency FROM AccountsPayableReceivables WHERE AccountsPayableReceivables.ReceivableId = R.Id) AS ReceivableAmountApplied_Currency
FROM PaymentVoucherReceivableOffsets PVRO
JOIN PaymentVouchers PV
ON PVRO.PaymentVoucherId = PV.Id
JOIN AccountsPayableReceivables APR
ON PVRO.ReceivableId = APR.Id AND APR.IsActive = 1
JOIN Receivables R
ON APR.ReceivableId = R.Id AND R.IsActive = 1
JOIN CTE_ReceivableIds
ON R.Id = CTE_ReceivableIds.ReceivableId
WHERE PVRO.PaymentVoucherId <> @PaymentVoucherId
AND PV.Status <> 'Reversed'
GROUP BY R.Id
),
CTE_ReceivableContractSequenceNumber
AS
(
SELECT
R.Id AS ReceivableId,
CASE
--WHEN (R.ContractId IS NOT NULL) THEN RC.SequenceNumber
WHEN (S.ContractId IS NOT NULL) THEN SC.SequenceNumber
ELSE ''
END AS ContractSequenceNumber
FROM
Receivables R
JOIN CTE_ReceivableIds
ON R.Id = CTE_ReceivableIds.ReceivableId
--LEFT JOIN Contracts RC
--	ON R.ContractId = RC.Id
LEFT JOIN Sundries S
ON R.Id = S.ReceivableId
LEFT JOIN Contracts SC
ON S.ContractId = SC.Id
)
SELECT
--R.Id AS ReceivableId,
RT.Name AS ReceivableType,
P.PartyName AS CustomerName,
P.PartyNumber AS CustomerPartyNumber,
R.Id AS ReceivableId,
PVRO.AmountToApply_Amount,
PVRO.AmountToApply_Currency,
RAD.ReceivableAmount_Amount,
RAD.ReceivableAmount_Currency,
RAD.ReceivableBalance_Amount,
RAD.ReceivableBalance_Currency,
RAD.ReceivableEffectiveBalance_Amount,
RAD.ReceivableEffectiveBalance_Currency,
CASE WHEN RAOV.ReceivableAmountApplied_Amount IS NULL THEN 0.00 ELSE RAOV.ReceivableAmountApplied_Amount END AS ReceivableAmountAppliedInOtherVouchers_Amount,
CASE WHEN RAOV.ReceivableAmountApplied_Currency IS NULL THEN PVRO.AmountToApply_Currency ELSE RAOV.ReceivableAmountApplied_Currency END AS ReceivableAmountAppliedInOtherVouchers_Currency,
RCSN.ContractSequenceNumber
FROM
PaymentVoucherReceivableOffsets PVRO
JOIN AccountsPayableReceivables APR
ON PVRO.ReceivableId = APR.Id AND APR.IsActive = 1
JOIN Receivables R
ON APR.ReceivableId = R.Id AND R.IsActive = 1
JOIN ReceivableCodes RC
ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT
ON RC.ReceivableTypeId = RT.Id
LEFT JOIN Parties P
ON R.CustomerId = P.Id
JOIN CTE_ReceivableAmountDetails RAD
ON R.Id = RAD.ReceivableId
LEFT JOIN CTE_ReceivableApplicationInOtherVouchers RAOV
ON R.Id = RAOV.ReceivableId
JOIN CTE_ReceivableContractSequenceNumber RCSN
ON R.Id = RCSN.ReceivableId
WHERE
PVRO.PaymentVoucherId = @PaymentVoucherId
END

GO
