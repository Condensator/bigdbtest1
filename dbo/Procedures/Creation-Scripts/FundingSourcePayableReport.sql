SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FundingSourcePayableReport]
(
@ContractID bigint = NULL,
@FunderID bigint = NULL
)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
;WITH CTE_ServicingDetails
AS (SELECT
ReceivableForTransfers.Id ReceivableForTransferId,
ReceivableForTransferServicings.Id,
ReceivableForTransferServicings.EffectiveDate,
RANK() OVER (PARTITION BY ReceivableForTransfers.Id ORDER BY ReceivableForTransferServicings.Id DESC) AS Rank
FROM ReceivableForTransfers
INNER JOIN ReceivableForTransferServicings
ON ReceivableForTransfers.id = ReceivableForTransferId
AND ReceivableForTransfers.ContractId = @ContractID
WHERE ReceivableForTransferServicings.IsActive = 1
AND ReceivableForTransferServicings.IsCollected = 1),
CTE_ReceivableForTransferDetails
AS (SELECT
ReceivableForTransfers.Id,
Parties.PartyName FunderName,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN LeasePaymentSchedules.StartDate
ELSE LoanPaymentSchedules.StartDate
END StartDate,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN LeasePaymentSchedules.EndDate
ELSE LoanPaymentSchedules.EndDate
END EndDate,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN LeasePaymentSchedules.DueDate
ELSE LoanPaymentSchedules.DueDate
END DueDate,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN ISNULL(LeasePaymentSchedules.Amount_Amount, 0.00)
ELSE ISNULL(LoanPaymentSchedules.Amount_Amount, 0.00)
END TotalPaymentAmount,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN ISNULL(LeasePaymentSchedules.Amount_Currency, 'USD')
ELSE ISNULL(LoanPaymentSchedules.Amount_Currency, 'USD')
END TotalPaymentCurrency,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN ISNULL(LeasePaymentSchedules.Amount_Currency, 'USD')
ELSE ISNULL(LoanPaymentSchedules.Amount_Currency, 'USD')
END PaymentDueToFunderCurrency,
ReceivableForTransferFundingSources.ParticipationPercentage,
ReceivableForTransferFundingSources.ScrapeFactor,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN LeasePaymentSchedules.PaymentType
ELSE LoanPaymentSchedules.PaymentType
END PaymentType,
CASE
WHEN ReceivableForTransfers.ContractType LIKE '%Lease%' THEN 0
ELSE ISNULL(LoanFinances.IsDailySensitive, 0)
END IsDailySensitiveLoan
FROM ReceivableForTransfers
INNER JOIN CTE_ServicingDetails
ON CTE_ServicingDetails.ReceivableForTransferId = ReceivableForTransfers.Id
AND CTE_ServicingDetails.Rank = 1
INNER JOIN ReceivableForTransferFundingSources
ON ReceivableForTransferFundingSources.ReceivableForTransferId = ReceivableForTransfers.Id
AND ReceivableForTransferFundingSources.IsActive = 1
INNER JOIN Funders
ON ReceivableForTransferFundingSources.FunderId = Funders.Id
INNER JOIN Parties
ON Funders.Id = Parties.id
INNER JOIN Contracts
ON Contracts.Id = ReceivableForTransfers.ContractId
LEFT JOIN LeaseFinances
ON LeaseFinances.ContractId = Contracts.Id
AND LeaseFinances.IsCurrent = 1
LEFT JOIN LeasePaymentSchedules
ON LeaseFinances.Id = LeasePaymentSchedules.LeaseFinanceDetailId
AND LeasePaymentSchedules.StartDate >= CTE_ServicingDetails.EffectiveDate
AND (LeasePaymentSchedules.PaymentType = 'FixedTerm'
OR LeasePaymentSchedules.PaymentType = 'Downpayment')
AND LeasePaymentSchedules.IsActive = 1
LEFT JOIN LoanFinances
ON LoanFinances.ContractId = ReceivableForTransfers.ContractId
AND LoanFinances.IsCurrent = 1
LEFT JOIN LoanPaymentSchedules
ON LoanFinances.Id = LoanPaymentSchedules.LoanFinanceId
AND LoanPaymentSchedules.StartDate >= CTE_ServicingDetails.EffectiveDate
AND LoanPaymentSchedules.PaymentType <> 'Interim'
AND LoanPaymentSchedules.IsActive = 1
AND LoanPaymentSchedules.IsFromReceiptPosting = 0
WHERE ReceivableForTransfers.ApprovalStatus <> 'Inactive'
AND ReceivableForTransfers.ContractId = @ContractID
AND (@FunderID IS NULL
OR ReceivableForTransferFundingSources.FunderId = @FunderID))
SELECT
FunderName,
StartDate,
EndDate,
DueDate,
SUM(TotalPaymentAmount) PaymentAmount,
TotalPaymentCurrency PaymentAmount_Currency,
ROUND(((SUM(TotalPaymentAmount) * ParticipationPercentage) / 100), 2) PaymentDueToFunder,
PaymentDueToFunderCurrency,
ROUND((((SUM(TotalPaymentAmount) * ParticipationPercentage) / 100) * ScrapeFactor), 2) ScrapeAmount,
PaymentDueToFunderCurrency ScrapeAmountCurrency,
PaymentType,
ParticipationPercentage,
ScrapeFactor,
IsDailySensitiveLoan INTO #ReceivableForTransferDetails_Temp
FROM CTE_ReceivableForTransferDetails
WHERE StartDate IS NOT NULL
GROUP BY	FunderName,
StartDate,
EndDate,
DueDate,
TotalPaymentCurrency,
PaymentDueToFunderCurrency,
ParticipationPercentage,
ScrapeFactor,
PaymentType,
IsDailySensitiveLoan
IF ((SELECT TOP (1) IsDailySensitiveLoan FROM #ReceivableForTransferDetails_Temp) = 1) BEGIN
DECLARE @MaxIncomeDate DATE = NULL
SELECT
@MaxIncomeDate = MAX(IncomeDate)
FROM LoanIncomeSchedules
INNER JOIN LoanFinances
ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId
WHERE LoanIncomeSchedules.IsSchedule = 1
AND ContractId = @ContractID;
IF @MaxIncomeDate IS NOT NULL BEGIN
DECLARE @CurrentLoanFinanceId BIGINT;
SELECT
@CurrentLoanFinanceId = Id
FROM LoanFinances
WHERE ContractId = @ContractID
AND IsCurrent = 1
DECLARE @startdate DATE, @enddate DATE;
DECLARE dslCursor CURSOR FOR
SELECT startdate, enddate FROM #ReceivableForTransferDetails_Temp WHERE PaymentType <> 'Paydown';
OPEN dslCursor
FETCH NEXT FROM dslCursor INTO @startdate, @enddate
WHILE @@FETCH_STATUS = 0 BEGIN
DECLARE @ReceiptPostedAmount DECIMAL(18,2) = 0.0;
DECLARE @PaydownAmount DECIMAL(18,2) = 0.0;
SELECT
@PaydownAmount = ISNULL(ROUND(SUM(Amount_Amount), 2), 0.00)
FROM LoanPaymentSchedules
WHERE LoanFinanceId = @CurrentLoanFinanceId
AND IsActive = 1
AND PaymentType = 'Paydown'
AND EndDate BETWEEN @startdate AND @enddate;
SELECT
@ReceiptPostedAmount = ISNULL(ROUND(SUM(Payment_Amount), 2), 0.00)
FROM LoanIncomeSchedules
INNER JOIN LoanFinances
ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId
WHERE LoanIncomeSchedules.IsSchedule = 1 AND LoanIncomeSchedules.IsLessorOwned = 0
AND ContractId = @ContractID AND IncomeDate BETWEEN @startdate AND @enddate;
SET @ReceiptPostedAmount = @ReceiptPostedAmount - @PaydownAmount;
IF (@MaxIncomeDate <= @enddate AND @ReceiptPostedAmount > 0.0) OR (@MaxIncomeDate > @enddate) BEGIN
UPDATE #ReceivableForTransferDetails_Temp
SET	#ReceivableForTransferDetails_Temp.PaymentAmount =  @ReceiptPostedAmount,
#ReceivableForTransferDetails_Temp.PaymentDueToFunder = ROUND(((@ReceiptPostedAmount * ParticipationPercentage) / 100), 2),
#ReceivableForTransferDetails_Temp.ScrapeAmount = ROUND((((@ReceiptPostedAmount * ParticipationPercentage) / 100) * ScrapeFactor), 2)
WHERE #ReceivableForTransferDetails_Temp.StartDate = @startdate
AND #ReceivableForTransferDetails_Temp.Enddate = @enddate
END
FETCH NEXT FROM dslCursor INTO @startdate, @enddate
END
CLOSE dslCursor
DEALLOCATE dslCursor
END
END
SELECT
FunderName,
StartDate,
EndDate,
DueDate,
PaymentAmount,
PaymentAmount_Currency,
PaymentDueToFunder,
PaymentDueToFunderCurrency,
ScrapeAmount,
PaymentDueToFunderCurrency ScrapeAmountCurrency,
PaymentType
FROM #ReceivableForTransferDetails_Temp;
DROP TABLE #ReceivableForTransferDetails_Temp;

GO
