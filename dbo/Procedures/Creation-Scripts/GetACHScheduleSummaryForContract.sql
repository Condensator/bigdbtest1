SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetACHScheduleSummaryForContract]
(
@ContractSequenceNumber nvarchar(80)
)
AS
SET NOCOUNT ON
BEGIN
DECLARE @ReceivableAndTaxInfo TABLE(ReceivableId BIGINT,DueDate DATETIME,ReceivableTypeName NVARCHAR(60),ReceivableBalanceAmount DECIMAL(16,2),ReceivableTotalAmount DECIMAL(16,2)
,TaxDue DECIMAL(16,2),TaxBalance DECIMAL(16,2))
INSERT INTO @ReceivableAndTaxInfo(ReceivableBalanceAmount,ReceivableTotalAmount,TaxDue,TaxBalance,ReceivableId,DueDate,ReceivableTypeName)
SELECT
SUM(ISNULL(RD.EffectiveBalance_Amount,0.00)) ReceivableBalanceAmount
,SUM(ISNULL(RD.Amount_Amount,0.00)) ReceivableTotalAmount
--,SUM(ISNULL(RTI.Amount_Amount,0.00)) TaxDue
,SUM(ISNULL(RTD.Amount_Amount,0.00)) TaxDue
--,SUM(ISNULL(RTI.EffectiveBalance_Amount,0.00)) TaxBalance
,SUM(ISNULL(RTD.EffectiveBalance_Amount,0.00)) TaxBalance
,R.Id ReceivableId
,R.DueDate
,RecT.Name
FROM
Receivables R
INNER JOIN ReceivableDetails RD on
R.Id = RD.ReceivableId
AND R.IsActive = 1
AND RD.IsActive = 1
AND R.EntityType = 'CT'
INNER JOIN Contracts C on
R.EntityId = C.Id
AND C.SequenceNumber = @ContractSequenceNumber
AND R.EntityType = 'CT'
INNER JOIN ReceivableCodes RC on
R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RecT ON
RC.ReceivableTypeId = RecT.Id
LEFT JOIN ReceivableTaxes RT ON
RT.ReceivableId =R.Id
LEFT JOIN ReceivableTaxDetails RTD On
RT.Id = RTD.ReceivableTaxId
AND RTD.IsActive = 1
--LEFT JOIN ReceivableTaxImpositions RTI On
--RTD.Id = RTI.ReceivableTaxDetailId
GROUP BY R.Id,R.DueDate,RecT.Name
DECLARE @ReceivablePaymentSchedule TABLE(ReceivableId BIGINT,PaymentNumber INT)
INSERT INTO @ReceivablePaymentSchedule(ReceivableId,PaymentNumber)
SELECT
R.Id
,ISNULL(ISNULL(LeasePS.PaymentNumber,LoanPS.PaymentNumber),0) PaymentNumber
FROM
Receivables as R
INNER JOIN Contracts C on
R.EntityId = C.Id
AND C.SequenceNumber = @ContractSequenceNumber
AND R.EntityType = 'CT'
AND R.IsActive = 1
LEFT JOIN LeasePaymentSchedules LeasePS ON
R.PaymentScheduleId = LeasePS.Id
LEFT JOIN LoanPaymentSchedules LoanPS ON
R.PaymentScheduleId = LoanPS.Id
SELECT Distinct
RTI.ReceivableId
,RTI.ReceivableTotalAmount
,RTI.ReceivableBalanceAmount
,RTI.DueDate
,RTI.TaxDue
,RTI.TaxBalance
,RPS.PaymentNumber
,ACHSchedules.ACHPaymentNumber
,ACHSchedules.ACHAmount_Amount ACHAmount
,ACHSchedules.PaymentType
,ACHSchedules.ACHAmount_Currency Currency
FROM
@ReceivableAndTaxInfo AS RTI
INNER JOIN @ReceivablePaymentSchedule AS RPS ON
RTI.ReceivableId = RPS.ReceivableId
INNER JOIN ACHSchedules on
RTI.ReceivableId = ACHSchedules.ReceivableId
AND ACHSchedules.IsActive = 1
END

GO
