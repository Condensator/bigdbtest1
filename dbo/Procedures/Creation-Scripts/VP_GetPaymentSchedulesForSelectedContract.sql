SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetPaymentSchedulesForSelectedContract]
(
@SequenceNumber NVARCHAR(40)=NULL,
@ContractType NVARCHAR(14)=NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF(@ContractType =''Lease'')
BEGIN
SELECT
LeasePayment.PaymentNumber
,LeasePayment.DueDate
,LeasePayment.PaymentType
,LeasePayment.PaymentStructure
,LeasePayment.Amount_Amount AS Payment_Amount
,LeasePayment.Amount_Currency AS Payment_Currency
,LeasePayment.Amount_Amount AS Balance_Amount
,LeasePayment.Amount_Currency AS Balance_Currency
FROM Contracts C
JOIN LeaseFinances Lease ON C.Id = Lease.ContractId AND C.SequenceNumber=@SequenceNumber
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
JOIN LeasePaymentSchedules LeasePayment ON LeaseDetail.Id = LeasePayment.LeaseFinanceDetailId
LEFT JOIN Receivables R ON LeasePayment.Id= R.PaymentScheduleId
LEFT JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
WHERE Lease.IsCurrent=1
AND LeasePayment.PaymentType!=''DownPayment''
AND LeasePayment.IsActive=1
AND (R.EntityId IS NULL OR R.EntityId=C.Id)
AND (R.EntityType IS NULL OR R.EntityType=''CT'')
AND (R.IsActive IS NULL OR R.IsActive=1)
GROUP BY R.PaymentScheduleId
,LeasePayment.PaymentNumber
,LeasePayment.DueDate
,LeasePayment.PaymentType
,LeasePayment.PaymentStructure
,LeasePayment.Amount_Amount
,LeasePayment.Amount_Currency
,RD.EffectiveBalance_Currency
END
ELSE IF(@ContractType =''Loan'' OR @ContractType =''ProgressLoan'')
BEGIN
SELECT
LoanPayment.PaymentNumber
,LoanPayment.DueDate
,LoanPayment.PaymentType
,LoanPayment.PaymentStructure
,LoanPayment.Amount_Amount AS Payment_Amount
,LoanPayment.Amount_Currency AS Payment_Currency
,LoanPayment.Amount_Amount AS Balance_Amount
,LoanPayment.Amount_Currency AS Balance_Currency
FROM Contracts C
JOIN LoanFinances Loan ON C.Id = Loan.ContractId  AND C.SequenceNumber=@SequenceNumber
JOIN LoanPaymentSchedules LoanPayment ON Loan.Id = LoanPayment.LoanFinanceId
LEFT JOIN Receivables R ON LoanPayment.Id= R.PaymentScheduleId
LEFT JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
WHERE Loan.IsCurrent=1
AND LoanPayment.PaymentType!=''DownPayment''
AND LoanPayment.IsActive=1
AND (R.EntityId IS NULL OR R.EntityId=C.Id)
AND (R.EntityType IS NULL OR R.EntityType=''CT'')
AND (R.IsActive IS NULL OR R.IsActive=1)
GROUP BY R.PaymentScheduleId
,LoanPayment.PaymentNumber
,LoanPayment.DueDate
,LoanPayment.PaymentType
,LoanPayment.PaymentStructure
,LoanPayment.Amount_Amount
,LoanPayment.Amount_Currency
,LoanPayment.EndBalance_Amount
,LoanPayment.EndBalance_Currency
,RD.EffectiveBalance_Currency
END
'
EXEC sp_executesql @Sql,N'
@SequenceNumber NVARCHAR(40)=NULL,
@ContractType NVARCHAR(14)=NULL'
,@SequenceNumber
,@ContractType

GO
