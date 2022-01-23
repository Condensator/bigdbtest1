SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingPaydownContractsInfo]
(
@DiscountingFinanceId BIGINT,
@ValidPaymentTypes NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
SELECT ContractId = ContractId, DiscountingContractId = DC.Id INTO #SelectedContracts
FROM DiscountingFinances DF
JOIN DiscountingContracts DC ON DF.Id = DC.DiscountingFinanceId
WHERE DF.Id = @DiscountingFinanceId
AND DC.IsActive = 1
--- Lease Contract Info----
SELECT
ContractId = LF.ContractId,
BookedResidual = SUM(LA.BookedResidual_Amount)
INTO #LeaseBookedResidualInfo
FROM LeaseFinances LF
JOIN #SelectedContracts CT ON LF.ContractId = CT.ContractId
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId
WHERE LF.IsCurrent = 1
AND LA.IsActive = 1
GROUP BY LF.ContractId
SELECT
SequenceNumber = C.SequenceNumber,
ContractType = C.ContractType,
Advance = LFD.IsAdvance,
Customer = P.PartyName,
MaturityDate = LFD.MaturityDate,
CommencementDate = LFD.CommencementDate,
DiscountingContractId = CT.DiscountingContractId,
ContractId = CT.ContractId,
DiscountRate = DC.DiscountRate,
PaidOffDate = DC.PaidOffDate,
ContractStatus = C.Status,
BookedResidual = ISNULL(BR.BookedResidual,0.00),
ResidualBalance = ISNULL(DC.ResidualBalance_Amount,0.00)
INTO #SelectedDiscountingPaydownContractInfo
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN DiscountingContracts DC ON CT.DiscountingContractId = DC.Id
JOIN LeaseFinances Lease ON Lease.ContractId = C.Id
JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
JOIN Parties P ON Lease.CustomerId = P.Id
LEFT JOIN #LeaseBookedResidualInfo BR ON CT.ContractId = BR.ContractId
WHERE C.ContractType ='Lease'
AND Lease.IsCurrent =1
--- Loan Contract Info----
INSERT INTO #SelectedDiscountingPaydownContractInfo
SELECT
SequenceNumber = C.SequenceNumber,
ContractType = C.ContractType,
Advance = LF.IsAdvance,
Customer = P.PartyName,
MaturityDate = LF.MaturityDate,
CommencementDate = LF.CommencementDate,
DiscountingContractId = CT.DiscountingContractId,
ContractId = CT.ContractId,
DiscountRate = DC.DiscountRate,
PaidOffDate = DC.PaidOffDate,
ContractStatus = C.Status,
BookedResidual = CAST(0.00 AS DECIMAL(16,2)),
ResidualBalance = ISNULL(DC.ResidualBalance_Amount,0.00)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN DiscountingContracts DC ON CT.DiscountingContractId = DC.Id
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN Parties P ON LF.CustomerId = P.Id
WHERE C.ContractType ='Loan'
AND LF.IsCurrent =1
--------PAYMENT SCHEDULE INFO---------------------------------------------------------------------------
DECLARE @IsTiedDiscounting BIT = (SELECT Tied FROM DiscountingFinances where Id= @DiscountingFinanceId)
CREATE TABLE #SelectedDiscountingPaydownContractPaymentScheduleInfo
(
ContractId BIGINT,
PaymentScheduleId BIGINT,
RepaymentScheduleId BIGINT,
FullPaymentAmount DECIMAL(16,2),
Amount DECIMAL(16,2),
Balance DECIMAL(16,2),
DueDate DATE,
SharedPercentage DECIMAL(5, 2),
SharedAmount DECIMAL(16,2),
IsAnyDiscountingOnHold BIT
)
CREATE TABLE #DiscountingDetails
(
PaymentScheduleId BIGINT,
SharedAmount DECIMAL(16,2),
SharedPercentage DECIMAL(5, 2),
IsAnyDiscountingOnHold BIT,
ContractId BIGINT
)
IF(@IsTiedDiscounting = 1)
BEGIN
--- Active Lease Payment Schedules----
INSERT INTO #SelectedDiscountingPaydownContractPaymentScheduleInfo
SELECT
ContractId = TD.ContractId,
PaymentScheduleId = LPS.Id,
RepaymentScheduleId = RS.Id,
FullPaymentAmount = LPS.Amount_Amount,
Amount = TD.SharedAmount_Amount,
Balance = TD.Balance_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2)),
IsAnyDiscountingOnHold = CAST(0 AS BIT)
FROM TiedContractPaymentDetails TD
JOIN Contracts ON TD.ContractId = Contracts.Id AND Contracts.ContractType = 'Lease'
JOIN LeasePaymentSchedules LPS ON TD.PaymentScheduleId = LPS.Id
JOIN LeaseFinances LF ON LPS.LeaseFinanceDetailId = LF.Id AND LF.IsCurrent=1
JOIN DiscountingRepaymentSchedules RS ON TD.DiscountingRepaymentScheduleId = RS.Id
JOIN DiscountingFinances DF ON RS.DiscountingFinanceId = DF.Id
WHERE DF.Id = @DiscountingFinanceId
AND LPS.IsActive =1
--- Active Loan Payment Schedules----
INSERT INTO #SelectedDiscountingPaydownContractPaymentScheduleInfo
SELECT
ContractId = TD.ContractId,
PaymentScheduleId = LPS.Id,
RepaymentScheduleId = RS.Id,
FullPaymentAmount = LPS.Amount_Amount,
Amount = TD.SharedAmount_Amount,
Balance = TD.Balance_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2)),
IsAnyDiscountingOnHold = CAST(0 AS BIT)
FROM TiedContractPaymentDetails TD
JOIN Contracts ON TD.ContractId = Contracts.Id AND Contracts.ContractType = 'Loan'
JOIN LoanPaymentSchedules LPS ON TD.PaymentScheduleId = LPS.Id
JOIN LoanFinances LF ON LPS.LoanFinanceId = LF.Id AND LF.IsCurrent=1
JOIN DiscountingRepaymentSchedules RS ON TD.DiscountingRepaymentScheduleId = RS.Id
JOIN DiscountingFinances DF ON RS.DiscountingFinanceId = DF.Id
WHERE DF.Id = @DiscountingFinanceId
AND LPS.IsActive =1
----Update Shared Percentage and Amount-----
INSERT INTO #DiscountingDetails
SELECT
PaymentScheduleId = PaymentTied.PaymentScheduleId,
SharedAmount = SUM(PaymentTiedToOtherDiscounting.SharedAmount_Amount),
SharedPercentage = SUM(DF.SharedPercentage),
IsAnyDiscountingOnHold = CASE WHEN ContractsWithDiscountingOnHold.ContractId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
ContractId = PaymentTied.ContractId
FROM #SelectedDiscountingPaydownContractPaymentScheduleInfo PaymentTied
JOIN TiedContractPaymentDetails PaymentTiedToOtherDiscounting ON PaymentTiedToOtherDiscounting.PaymentScheduleId = PaymentTied.PaymentScheduleId AND PaymentTied.ContractId = PaymentTiedToOtherDiscounting.ContractId
JOIN DiscountingRepaymentSchedules DRS ON PaymentTiedToOtherDiscounting.DiscountingRepaymentScheduleId = DRS.Id AND DRS.IsActive=1
JOIN DiscountingFinances DF ON DRS.DiscountingFinanceId = DF.Id AND DF.IsCurrent = 1
JOIN DiscountingContracts DC ON DF.Id = DC.DiscountingFinanceId AND PaymentTiedToOtherDiscounting.ContractId = DC.ContractId
LEFT JOIN (SELECT DiscountingContracts.ContractId
FROM #SelectedContracts
JOIN DiscountingContracts ON #SelectedContracts.ContractId = DiscountingContracts.ContractId AND DiscountingContracts.IsActive=1
JOIN DiscountingFinances ON DiscountingContracts.DiscountingFinanceId = DiscountingFinances.Id AND DiscountingFinances.IsCurrent=1
WHERE DiscountingFinances.IsOnHold=1
AND DiscountingFinances.Id <> @DiscountingFinanceId
GROUP BY DiscountingContracts.ContractId)
AS ContractsWithDiscountingOnHold ON DC.ContractId = ContractsWithDiscountingOnHold.ContractId
WHERE (DC.IsActive=1 OR DC.ReleasedDate IS NOT NULL)
AND DF.Id <> @DiscountingFinanceId AND DF.IsOnHold = 0
AND (DC.ReleasedDate IS NULL OR PaymentTiedToOtherDiscounting.IsActive=1)
GROUP BY PaymentTied.PaymentScheduleId,PaymentTied.ContractId,ContractsWithDiscountingOnHold.ContractId
UPDATE #SelectedDiscountingPaydownContractPaymentScheduleInfo
SET SharedAmount = DD.SharedAmount,
SharedPercentage = DD.SharedPercentage,
IsAnyDiscountingOnHold = DD.IsAnyDiscountingOnHold
FROM #DiscountingDetails DD
JOIN #SelectedDiscountingPaydownContractPaymentScheduleInfo CPSI ON DD.PaymentScheduleId = CPSI.PaymentScheduleId AND DD.ContractId = CPSI.ContractId
END
ELSE
BEGIN
--- Active Lease Payment Schedules----
INSERT INTO #SelectedDiscountingPaydownContractPaymentScheduleInfo
SELECT
ContractId = C.Id,
PaymentScheduleId = LPS.Id,
RepaymentScheduleId = 0,
FullPaymentAmount = LPS.Amount_Amount,
Amount = LPS.Amount_Amount,
Balance = LPS.Amount_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2)),
IsAnyDiscountingOnHold = CAST(0 AS BIT)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN DiscountingContracts DC ON CT.ContractId = DC.ContractId
JOIN LeaseFinances Lease ON Lease.ContractId = C.Id
JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId
JOIN ConvertCSVToStringTable(@ValidPaymentTypes, ',') VPT ON LPS.PaymentType = VPT.Item
WHERE C.ContractType ='Lease'
AND LPS.IsActive =1
AND Lease.IsCurrent =1
AND LPS.DueDate >= DC.EarliestDueDate
AND LPS.DueDate <= DC.EndDueDate
--- Active Loan Payment Schedules----
INSERT INTO #SelectedDiscountingPaydownContractPaymentScheduleInfo
SELECT
ContractId = C.Id,
PaymentScheduleId = LPS.Id,
RepaymentScheduleId = 0,
FullPaymentAmount = LPS.Amount_Amount,
Amount = LPS.Amount_Amount,
Balance = LPS.Amount_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2)),
IsAnyDiscountingOnHold = CAST(0 AS BIT)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN DiscountingContracts DC ON CT.ContractId = DC.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId
JOIN ConvertCSVToStringTable(@ValidPaymentTypes, ',') VPT ON LPS.PaymentType = VPT.Item
WHERE C.ContractType ='Loan'
AND LPS.IsActive =1
AND LF.IsCurrent =1
AND LPS.DueDate >= DC.EarliestDueDate
AND LPS.DueDate <= DC.EndDueDate
END
--------------------------------------------------------------------------------------------------------------
SELECT * FROM #SelectedDiscountingPaydownContractInfo
SELECT * FROM #SelectedDiscountingPaydownContractPaymentScheduleInfo
--------------------------------------------------------------------------------------------------------------
DROP TABLE #SelectedContracts
DROP TABLE #SelectedDiscountingPaydownContractInfo
DROP TABLE #LeaseBookedResidualInfo
DROP TABLE #SelectedDiscountingPaydownContractPaymentScheduleInfo
DROP TABLE #DiscountingDetails
SET NOCOUNT OFF;
END

GO
