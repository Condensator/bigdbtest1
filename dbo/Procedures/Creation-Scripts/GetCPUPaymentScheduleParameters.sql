SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCPUPaymentScheduleParameters]
(
@CPUContractInfo CPUContractInfoForGetCPUPaymentScheduleParameters READONLY ,
@IsForBasePayment BIT
)
AS
BEGIN
SET NOCOUNT ON;
IF OBJECT_ID('#CPUContractInfo') IS NULL
BEGIN
CREATE TABLE #CPUContractInfo
(
ContractSequenceNumber NVARCHAR(40) NOT NULL,
ScheduleNumber NVARCHAR(40) NOT NULL
)
END
INSERT INTO #CPUContractInfo
SELECT
CPUContractSequenceNumber, CPUScheduleNumber
FROM
@CPUContractInfo
WHERE
CPUScheduleNumber IS NOT NULL
IF ((SELECT COUNT(CPUContractSequenceNumber) FROM @CPUContractInfo WHERE CPUScheduleNumber IS NULL) > 0)
BEGIN
INSERT INTO #CPUContractInfo
SELECT
CPUContracts.SequenceNumber, CPUSchedules.ScheduleNumber
FROM
CPUContracts
JOIN CPUSchedules ON CPUContracts.CPUFinanceId = CPUSchedules.CPUFinanceId
WHERE
CPUContracts.[Status] IN ('Commenced'  , 'PaidOff' )
AND CPUSchedules.IsActive = 1
AND CPUContracts.SequenceNumber IN (SELECT DISTINCT(CPUContractSequenceNumber) FROM @CPUContractInfo WHERE CPUScheduleNumber IS NULL)
END
IF (@IsForBasePayment = 1)
BEGIN
SELECT
CPUTransactions.CPUFinanceId,
CPUTransactions.CPUContractId,
CPUSchedules.Id AS ScheduleId,
CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
CPUSchedules.ScheduleNumber AS CPUScheduleNumber,
CPUFinances.DueDay,
CPUFinances.IsAdvanceBilling,
CPUFinances.BasePaymentFrequency AS PaymentFrequency,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUSchedules.[CommencementDate]
ELSE
DATEADD(Day,1,CPUTransactions.Date)
END AS EffectiveFrom,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUSchedules.[CommencementDate]
ELSE
DATEADD(Day,1,CPUTransactions.Date)
END AS ScheduleEffectiveDate,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUBaseStructures.FrequencyStartDate
ELSE
NULL
END AS FrequencyStartDate
FROM
CPUTransactions
JOIN CPUContracts		ON	CPUContracts.Id = CPUTransactions.CPUContractId
JOIN CPUFinances		ON	CPUTransactions.CPUFinanceId = CPUFinances.Id
JOIN CPUSchedules		ON	CPUFinances.Id = CPUSchedules.CPUFinanceId
JOIN CPUBaseStructures	ON	CPUSchedules.Id = CPUBaseStructures.Id
JOIN #CPUContractInfo	ON	#CPUContractInfo.ContractSequenceNumber = CPUContracts.SequenceNumber
AND #CPUContractInfo.ScheduleNumber = CPUSchedules.ScheduleNumber
WHERE
CPUSchedules.IsActive = 1
AND CPUTransactions.IsActive = 1
AND CPUTransactions.TransactionType != 'Payoff'
ORDER BY
CPUScheduleNumber, EffectiveFrom
END
ELSE
BEGIN
SELECT
CPUTransactions.CPUFinanceId,
CPUTransactions.CPUContractId,
CPUSchedules.Id AS ScheduleId,
CPUContracts.SequenceNumber AS CPUContractSequenceNumber,
CPUSchedules.ScheduleNumber AS CPUScheduleNumber,
CPUOverageStructures.PaymentFrequency AS PaymentFrequency,
CPUFinances.DueDay,
CPUFinances.IsAdvanceBilling,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUSchedules.[CommencementDate]
ELSE
DATEADD(Day,1,CPUTransactions.Date)
END AS EffectiveFrom,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUSchedules.[CommencementDate]
ELSE
DATEADD(Day,1,CPUTransactions.Date)
END AS ScheduleEffectiveDate,
CASE
WHEN ([CPUSchedules].[CommencementDate] >= [CPUTransactions].[Date])
THEN
CPUOverageStructures.FrequencyStartDate
ELSE
NULL
END AS FrequencyStartDate
FROM
CPUTransactions
JOIN CPUContracts			ON	CPUContracts.Id = CPUTransactions.CPUContractId
JOIN CPUFinances			ON	CPUTransactions.CPUFinanceId = CPUFinances.Id
JOIN CPUSchedules			ON	CPUFinances.Id = CPUSchedules.CPUFinanceId
JOIN CPUOverageStructures	ON	CPUSchedules.Id = CPUOverageStructures.Id
JOIN #CPUContractInfo		ON	#CPUContractInfo.ContractSequenceNumber = CPUContracts.SequenceNumber
AND #CPUContractInfo.ScheduleNumber = CPUSchedules.ScheduleNumber
WHERE
CPUSchedules.IsActive = 1
AND CPUTransactions.IsActive = 1
AND CPUTransactions.TransactionType != 'Payoff'
ORDER BY
CPUScheduleNumber, EffectiveFrom
END
IF OBJECT_ID('#CPUContractInfo') IS NOT NULL
BEGIN
DROP TABLE #CPUContractInfo
END
SET NOCOUNT OFF;
END

GO
