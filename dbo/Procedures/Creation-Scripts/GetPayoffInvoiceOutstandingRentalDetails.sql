SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPayoffInvoiceOutstandingRentalDetails]
(
@PayoffId BIGINT,
@PayoffEffectiveDate DATE,
@Currency NVARCHAR(10),
@ContractId BIGINT,
@ContractReceivableEntityType NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #OutstandingReceivableDetails
(
ReceivableDetailId BIGINT,
ReceivableCodeName NVARCHAR(100),
Currency NVARCHAR(3),
DueDate DATE,
ReceivableAmount DECIMAL(16,2),
TaxAmount DECIMAL(16,2),
IsRental BIT,
IsTaxAssessed BIT,
ReceivableTypeId BIGINT,
HSTGSTTaxAmount DECIMAL(18,2),
QSTPSTTaxAmount DECIMAL(18,2),
ReceivableId BIGINT
)
INSERT INTO #OutstandingReceivableDetails
SELECT
ReceivableDetailId = RD.Id,
ReceivableCodeName = RC.Name,
Currency = @Currency,
DueDate = R.DueDate,
ReceivableAmount = ISNULL((SELECT TOP 1 EffectiveBalance_Amount from ReceivableDetails where Id=RD.Id),0.00),
TaxAmount = ISNULL(SUM(RTX.EffectiveBalance_Amount),0.0),
IsRental = 1,
IsTaxAssessed = RD.IsTaxAssessed,
ReceivableTypeId = RT.Id,
HSTGSTTaxAmount = 0.0,
QSTPSTTaxAmount = 0.0,
RD.ReceivableId
FROM ReceivableDetails RD WITH (NOLOCK)
JOIN Receivables R WITH (NOLOCK) ON RD.ReceivableId = R.Id
JOIN ReceivableCodes RC WITH (NOLOCK) ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT WITH (NOLOCK) ON RC.ReceivableTypeId = RT.Id
LEFT JOIN LeasePaymentSchedules LPS WITH (NOLOCK) ON R.PaymentScheduleId = LPS.Id
	AND R.EntityType = @ContractReceivableEntityType
	AND R.EntityId = @ContractId
	AND R.SourceTable = '_'
LEFT JOIN ReceivableTaxDetails RTX WITH (NOLOCK) ON RD.Id = RTX.ReceivableDetailId AND RTX.IsActive = 1 AND RTX.EffectiveBalance_Amount > 0
WHERE
RT.IsRental=1
AND RD.IsActive=1
AND R.IsDummy = 0
AND R.IsActive = 1
AND (LPS.Id IS NULL OR LPS.EndDate <= @PayoffEffectiveDate)
AND (LPS.Id IS NOT NULL OR R.DueDate <= @PayoffEffectiveDate)
AND R.EntityType = @ContractReceivableEntityType
AND R.EntityId = @ContractId
AND (RD.IsTaxAssessed = 0 OR R.TotalEffectiveBalance_Amount > 0 OR RTX.Id IS NOT NULL)
GROUP BY
RD.Id,
RC.Name,
R.DueDate,
RD.IsTaxAssessed,
RT.Id,
RD.ReceivableId
INSERT INTO #OutstandingReceivableDetails
SELECT
ReceivableDetailId = RD.Id,
ReceivableCodeName = RC.Name,
Currency = @Currency,
DueDate = R.DueDate,
ReceivableAmount = ISNULL((SELECT TOP 1 EffectiveBalance_Amount from ReceivableDetails where Id=RD.Id),0.00),
TaxAmount = ISNULL(SUM(RTX.EffectiveBalance_Amount),0.0),
IsRental = 0,
IsTaxAssessed = RD.IsTaxAssessed,
ReceivableTypeId = RT.Id,
HSTGSTTaxAmount =0.0,
QSTPSTTaxAmount = 0.0,
RD.ReceivableId
FROM ReceivableDetails RD WITH (NOLOCK)
JOIN Receivables R WITH (NOLOCK) ON RD.ReceivableId = R.Id
JOIN ReceivableCodes RC WITH (NOLOCK) ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT WITH (NOLOCK) ON RC.ReceivableTypeId = RT.Id
LEFT JOIN ReceivableTaxDetails RTX WITH (NOLOCK) ON RD.Id = RTX.ReceivableDetailId AND RTX.IsActive = 1 AND RTX.EffectiveBalance_Amount > 0
WHERE
R.IsDummy = 0
AND RD.IsActive=1
AND RT.IsRental = 0
AND RT.LeaseBased = 1
AND R.IsActive = 1
AND R.EntityType = @ContractReceivableEntityType
AND R.EntityId = @ContractId
AND (RD.IsTaxAssessed = 0 OR R.TotalEffectiveBalance_Amount > 0 OR RTX.Id IS NOT NULL)
GROUP BY
RD.Id,
RC.Name,
R.DueDate,
RD.IsTaxAssessed,
RT.Id,
RD.ReceivableId
UPDATE
#OutstandingReceivableDetails
SET
HSTGSTTaxAmount = T.HSTGSTTaxAmount
FROM
#OutstandingReceivableDetails
JOIN
(
SELECT
RD.Id,
HSTGSTTaxAmount = ISNULL(RTI.EffectiveBalance_Amount, 0.0)
FROM ReceivableDetails RD
JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId AND RTD.IsActive=1
JOIN ReceivableTaxes RT ON RTD.ReceivableTaxId=RT.Id AND RT.IsActive=1
JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId AND RTI.IsActive=1
WHERE RTI.ExternalTaxImpositionType IN('GST/HST','GST','HST')
)T ON T.Id = #OutstandingReceivableDetails.ReceivableDetailId
WHERE
T.Id = #OutstandingReceivableDetails.ReceivableDetailId
UPDATE
#OutstandingReceivableDetails
SET
QSTPSTTaxAmount = T.QSTPSTTaxAmount
FROM
#OutstandingReceivableDetails
JOIN
(
SELECT
RD.Id,
QSTPSTTaxAmount = ISNULL(RTI.EffectiveBalance_Amount, 0.0)
FROM ReceivableDetails RD
JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId AND RTD.IsActive=1
JOIN ReceivableTaxes RT ON RTD.ReceivableTaxId=RT.Id AND RT.IsActive=1
JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId AND RTI.IsActive=1
WHERE RTI.ExternalTaxImpositionType IN('PST/QST','PST','QST')
)T ON T.Id = #OutstandingReceivableDetails.ReceivableDetailId
WHERE
T.Id = #OutstandingReceivableDetails.ReceivableDetailId
SELECT
ReceivableDetailId = R.ReceivableDetailId,
ReceivableCodeName = R.ReceivableCodeName,
Currency = R.Currency,
DueDate = R.DueDate,
ReceivableAmount = R.ReceivableAmount,
TaxAmount = R.TaxAmount,
IsRental = R.IsRental,
IsTaxAssessed = R.IsTaxAssessed,
ReceivableTypeId = R.ReceivableTypeId,
HSTGSTTaxAmount = R.HSTGSTTaxAmount,
QSTPSTTaxAmount = R.QSTPSTTaxAmount,
R.ReceivableId
FROM
#OutstandingReceivableDetails R
DROP TABLE #OutstandingReceivableDetails
END

GO
