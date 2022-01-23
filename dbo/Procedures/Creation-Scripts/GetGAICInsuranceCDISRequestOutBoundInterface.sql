SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetGAICInsuranceCDISRequestOutBoundInterface]
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_ContractsForSkippedPayments
AS
(
SELECT
Count=COUNT(LeaseFinances.ContractId ),
ContractId=LeaseFinances.ContractId
FROM LeasePaymentSchedules
INNER JOIN LeaseFinances ON LeaseFinances.Id=LeasePaymentSchedules.LeaseFinanceDetailId AND LeaseFinances.IsCurrent=1 AND SendToGAIC=1 AND GAICStatus='Queued'
WHERE PaymentType='FixedTerm'
AND PaymentStructure!='InterestOnly'
AND Amount_Amount=0
GROUP BY LeaseFinances.ContractId
HAVING COUNT(LeaseFinances.ContractId )>0
UNION ALL
SELECT
Count=COUNT(LoanFinances.ContractId),
ContractId=LoanFinances.ContractId
FROM LoanPaymentSchedules
INNER JOIN LoanFinances ON LoanFinances.Id=LoanPaymentSchedules.LoanFinanceId AND LoanFinances.IsCurrent=1 AND IsSendToGAIC=1 AND GAICStatus='Queued'
WHERE PaymentType='FixedTerm'
AND PaymentStructure!='InterestOnly'
AND Amount_Amount=0
GROUP BY LoanFinances.ContractId
HAVING COUNT(LoanFinances.ContractId )>0
),
CTE_CommencedContracts As
(
SELECT
ContractId,
SequenceNumber,
InvoiceDueDate=DATEADD(dd,-(ContractBillings.InvoiceLeaddays),DueDate),
DueDate=DueDate
FROM
(
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
DueDate=LeasePaymentSchedules.DueDate
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND BookingStatus='Commenced' AND Contracts.Status='Commenced' AND LeaseFinances.IsCurrent=1 AND SendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.LeaseFinanceDetailId=LeaseFinances.Id AND LeasePaymentSchedules.PaymentType NOT IN ('ThirdPartyGuaranteedResidual','CustomerGuaranteedResidual')
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
LeasePaymentSchedules.DueDate
UNION ALL
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
DueDate=LoanPaymentSchedules.DueDate
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id=LoanFinances.ContractId AND LoanFinances.Status='Commenced' AND Contracts.Status='Commenced' AND LoanFinances.IsCurrent=1 AND IsSendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LoanPaymentSchedules ON LoanPaymentSchedules.LoanFinanceId=LoanFinances.Id AND LoanPaymentSchedules.PaymentType NOT IN ('ThirdPartyGuaranteedResidual','CustomerGuaranteedResidual')
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
LoanPaymentSchedules.DueDate
)TEMP
INNER JOIN ContractBillings On ContractBillings.Id=Temp.ContractId
),
CTE_TerminatedContracts As
(
SELECT
ContractId=TEMP.ContractId,
SequenceNumber,
InvoiceDueDate=DATEADD(dd,-(ContractBillings.InvoiceLeaddays),DueDate),
DueDate=DueDate
FROM
(
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
DueDate=LeasePaymentSchedules.DueDate
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND BookingStatus='Terminated' AND LeaseFinances.IsCurrent=1 AND SendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.LeaseFinanceDetailId=LeaseFinances.Id AND LeasePaymentSchedules.PaymentType NOT IN ('ThirdPartyGuaranteedResidual','CustomerGuaranteedResidual')
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
LeasePaymentSchedules.DueDate
UNION ALL
SELECT
ContractId=Contracts.Id,
SequenceNumber=Contracts.SequenceNumber,
DueDate=LoanPaymentSchedules.DueDate
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id=LoanFinances.ContractId AND LoanFinances.Status='Terminated' AND LoanFinances.IsCurrent=1 AND IsSendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LoanPaymentSchedules ON LoanPaymentSchedules.LoanFinanceId=LoanFinances.Id AND LoanPaymentSchedules.PaymentType NOT IN ('ThirdPartyGuaranteedResidual','CustomerGuaranteedResidual')
GROUP BY
Contracts.Id,
Contracts.SequenceNumber,
LoanPaymentSchedules.DueDate
)TEMP
INNER JOIN ContractBillings ON ContractBillings.Id=Temp.ContractId
INNER JOIN ContractTerminations ON ContractTerminations.ContractId=TEMP.ContractId
WHERE IsNULL(DATEDIFF(DD,ContractTerminations.TerminationDate,GETDATE()),0)<=7
),
CTE_ContractsForCDIS AS
(
Select * FROM CTE_CommencedContracts
UNION ALL
Select * FROM CTE_TerminatedContracts
),
CTE_ContractsWithPaymentSchedules As
(
SELECT
ContractId=Contracts.Id,
Count=COUNT(LeasePaymentSchedules.Id)
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id=LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1 AND SendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.LeaseFinanceDetailId=LeaseFinances.Id
GROUP BY
Contracts.Id
UNION ALL
SELECT
ContractId=Contracts.Id,
Count=COUNT(LoanPaymentSchedules.Id)
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id=LoanFinances.ContractId AND LoanFinances.IsCurrent=1 AND IsSendToGAIC=1 AND GAICStatus='Queued'
INNER JOIN LoanPaymentSchedules ON LoanPaymentSchedules.LoanFinanceId=LoanFinances.Id
GROUP BY
Contracts.Id
)
SELECT
TransactionCode='',
ContractNumber=CTE_ContractsForCDIS.SequenceNumber,
InvoiceDate=CONVERT(NVARCHAR(10),CTE_ContractsForCDIS.InvoiceDueDate,101),
DueDate=CONVERT(NVARCHAR(10),CTE_ContractsForCDIS.DueDate,101),
ContractInvoiceCount=CTE_ContractsWithPaymentSchedules.Count
FROM CTE_ContractsForCDIS
INNER JOIN CTE_ContractsForSkippedPayments ON CTE_ContractsForCDIS.ContractId=CTE_ContractsForSkippedPayments.ContractId
INNER JOIN CTE_ContractsWithPaymentSchedules ON CTE_ContractsWithPaymentSchedules.ContractId=CTE_ContractsForCDIS.ContractId
ORDER BY CTE_ContractsForCDIS.SequenceNumber
END

GO
