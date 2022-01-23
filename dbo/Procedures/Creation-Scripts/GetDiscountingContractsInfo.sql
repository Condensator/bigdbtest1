SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDiscountingContractsInfo]
(
@ContractId DiscountingContractIdsInfo READONLY,
@ValidPaymentTypes NVARCHAR(MAX),
@IsRestructure Bit,
@DiscountingId BigInt
)
AS
BEGIN
SET NOCOUNT ON;
SELECT ContractId = ContractId INTO #SelectedContracts FROM @ContractId
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
ContractId = C.Id,
DayCountConvention = LFD.DayCountConvention,
PaymentFrequency = LFD.PaymentFrequency,
SharedPercentage = C.DiscountingSharedPercentage,
CompoundingFrequency = LFD.PaymentFrequency,
IsFloatRate = LFD.IsFloatRateLease,
IsDSLLoan = CAST(0 AS BIT),
BookedResidual = ISNULL(BR.BookedResidual,0.00),
AmendmentDate = CAST(NULL AS DATETIME)
INTO #SelectedDiscountingContractInfo
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LeaseFinances Lease ON Lease.ContractId = C.Id
JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
JOIN Parties P ON Lease.CustomerId = P.Id
LEFT JOIN #LeaseBookedResidualInfo BR ON CT.ContractId = BR.ContractId
WHERE C.ContractType ='Lease'
AND Lease.IsCurrent =1
--- Loan Contract Info----
SELECT DISTINCT
ContractId = CT.ContractId
INTO #LoanFloatRateInfo
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanInterestRates LIR ON LF.Id = LIR.LoanFinanceId
JOIN InterestRateDetails IRD ON LIR.InterestRateDetailId = IRD.Id AND IRD.IsFloatRate = 1
WHERE C.ContractType ='Loan'
AND LF.IsCurrent =1
GROUP BY CT.ContractId
INSERT INTO #SelectedDiscountingContractInfo
SELECT
SequenceNumber = C.SequenceNumber,
ContractType = C.ContractType,
Advance = LF.IsAdvance,
Customer = P.PartyName,
MaturityDate = LF.MaturityDate,
CommencementDate = LF.CommencementDate,
ContractId = C.Id,
DayCountConvention = LF.DayCountConvention,
PaymentFrequency = LF.PaymentFrequency,
SharedPercentage = C.DiscountingSharedPercentage,
CompoundingFrequency = LF.CompoundingFrequency,
IsFloatRate = CASE WHEN LFR.ContractId IS NOT NULL THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END,
IsDSLLoan = LF.IsDailySensitive,
BookedResidual = CAST(0.00 AS DECIMAL(16,2)),
AmendmentDate = CAST(NULL AS DATETIME)
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN Parties P ON LF.CustomerId = P.Id
LEFT JOIN #LoanFloatRateInfo LFR ON CT.ContractId = LFR.ContractId
WHERE C.ContractType ='Loan'
AND LF.IsCurrent =1
--Discounting Restructure
IF(@IsRestructure = 1)
BEGIN
DECLARE @SharedPercentageToBeReduced DECIMAL(5,2) =(SELECT DF.SharedPercentage FROM DiscountingFinances DF
JOIN Discountings D on D.Id = DF.DiscountingId
WHERE D.Id = @DiscountingId
and DF.IsCurrent = 1)
UPDATE #SelectedDiscountingContractInfo SET SharedPercentage = SharedPercentage - @SharedPercentageToBeReduced
UPDATE #SelectedDiscountingContractInfo SET AmendmentDate = DC.AmendmentDate
FROM #SelectedDiscountingContractInfo SDC
JOIN #SelectedContracts CT ON SDC.ContractId = CT.ContractId
JOIN DiscountingContracts DC ON CT.ContractId = DC.ContractId
JOIN DiscountingFinances DF ON DF.Id = DC.DiscountingFinanceId
WHERE DF.IsCurrent = 1
END
--- Active Lease Payment Schedules----
SELECT
ContractId = C.Id,
PaymentScheduleId = LPS.Id,
FullPaymentAmount = LPS.Amount_Amount,
Amount = LPS.Amount_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2))
INTO #SelectedDiscountingContractPaymentScheduleInfo
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LeaseFinances Lease ON Lease.ContractId = C.Id
JOIN LeaseFinanceDetails LFD ON Lease.Id = LFD.Id
JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId
JOIN ConvertCSVToStringTable(@ValidPaymentTypes, ',') VPT ON LPS.PaymentType = VPT.Item
WHERE C.ContractType ='Lease'
AND LPS.IsActive =1
AND Lease.IsCurrent =1
--- Active Loan Payment Schedules----
INSERT INTO #SelectedDiscountingContractPaymentScheduleInfo
SELECT
ContractId = C.Id,
PaymentScheduleId = LPS.Id,
FullPaymentAmount = LPS.Amount_Amount,
Amount = LPS.Amount_Amount,
DueDate = LPS.DueDate,
SharedPercentage = CAST(0.00 AS DECIMAL(5, 2)),
SharedAmount = CAST(0.00 AS DECIMAL(16,2))
FROM Contracts C
JOIN #SelectedContracts CT ON C.Id = CT.ContractId
JOIN LoanFinances LF ON LF.ContractId = C.Id
JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId
JOIN ConvertCSVToStringTable(@ValidPaymentTypes, ',') VPT ON LPS.PaymentType = VPT.Item
WHERE C.ContractType ='Loan'
AND LPS.IsActive =1
AND LF.IsCurrent =1
----Update Shared Percentage and Amount-----
SELECT
PaymentScheduleId = TCPD.PaymentScheduleId,
SharedAmount = SUM(TCPD.SharedAmount_Amount),
SharedPercentage = SUM(DF.SharedPercentage)
INTO #DiscountingDetails
FROM TiedContractPaymentDetails TCPD
JOIN DiscountingRepaymentSchedules DRS ON TCPD.DiscountingRepaymentScheduleId = DRS.Id AND DRS.IsActive=1
JOIN DiscountingFinances DF ON DRS.DiscountingFinanceId = DF.Id AND DF.IsCurrent = 1
JOIN DiscountingContracts DC ON DF.Id = DC.DiscountingFinanceId AND DC.IsActive=1
JOIN Discountings D ON DF.DiscountingId = D.Id
JOIN #SelectedContracts CT ON DC.ContractId = CT.ContractId
WHERE
(@IsRestructure = 1 and D.Id <> @DiscountingId)
AND TCPD.IsActive=1
GROUP BY TCPD.PaymentScheduleId
UPDATE #SelectedDiscountingContractPaymentScheduleInfo
SET SharedAmount = DD.SharedAmount,
SharedPercentage = DD.SharedPercentage
FROM #DiscountingDetails DD
JOIN #SelectedDiscountingContractPaymentScheduleInfo CPSI ON DD.PaymentScheduleId = CPSI.PaymentScheduleId
--------------------------------------------------------------------------------------------------------------
SELECT * FROM #SelectedDiscountingContractInfo
SELECT * FROM #SelectedDiscountingContractPaymentScheduleInfo
--------------------------------------------------------------------------------------------------------------
DROP TABLE #SelectedContracts
DROP TABLE #SelectedDiscountingContractInfo
DROP TABLE #SelectedDiscountingContractPaymentScheduleInfo
DROP TABLE #LeaseBookedResidualInfo
DROP TABLE #DiscountingDetails
DROP TABLE #LoanFloatRateInfo
SET NOCOUNT OFF;
END

GO
