SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[GetPayoffOutstandingChargesForSelectedReceivable]
(
@receivableIds NVARCHAR(max),
@Currency NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT * INTO #ReceivableIds FROM ConvertCSVToBigIntTable(@receivableIds, ',');
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
insert into #OutstandingReceivableDetails
SELECT    DISTINCT
ReceivableDetailId = RD.Id,
ReceivableCodeName = RC.Name,
Currency = @Currency,
DueDate = R.DueDate,
ReceivableAmount = ISNULL((SELECT TOP 1 EffectiveBalance_Amount from ReceivableDetails where Id=RD.Id),0.00),
TaxAmount = ISNULL(SUM(RTX.EffectiveBalance_Amount),0.0),
IsRental = RT.IsRental,
IsTaxAssessed = RD.IsTaxAssessed,
ReceivableTypeId = RT.Id,
HSTGSTTaxAmount = 0.0,
QSTPSTTaxAmount = 0.0,
RD.ReceivableId
FROM ReceivableDetails RD WITH (NOLOCK)
join #ReceivableIds rid on RD.ReceivableId = rid.ID
join Receivables R WITH (NOLOCK)  on R.Id = rid.ID
JOIN ReceivableCodes RC WITH (NOLOCK) ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT WITH (NOLOCK) ON RC.ReceivableTypeId = RT.Id
LEFT JOIN ReceivableTaxDetails RTX WITH (NOLOCK) ON RTX.ReceivableDetailId = RD.Id  AND RTX.IsActive = 1 AND RTX.EffectiveBalance_Amount != 0
where RD.IsActive = 1 and R.IsDummy = 0  and R.IsActive = 1
and (RD.IsTaxAssessed = 0 or R.TotalEffectiveBalance_Amount != 0 or RTX.Id is not null)
GROUP BY
RD.Id,
RC.Name,
R.DueDate,
RD.IsTaxAssessed,
RT.Id,
RD.ReceivableId ,
RT.IsRental
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
WHERE T.Id = #OutstandingReceivableDetails.ReceivableDetailId

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
WHERE T.Id = #OutstandingReceivableDetails.ReceivableDetailId
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
FROM  #OutstandingReceivableDetails R
DROP TABLE #OutstandingReceivableDetails
DROP TABLE #ReceivableIds
END

GO
