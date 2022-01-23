SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractDiscountingDetailsForReceipt]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@ReceivableTypeValues_BuyOut						NVARCHAR(40),
@YesNoValues_No										NVARCHAR(40)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
;WITH CTE_ContractsWithDiscounting AS
(
SELECT RARD.ContractId
FROM ReceiptReceivableDetails_Extract RARD
INNER JOIN Contracts C ON RARD.ContractId = C.Id AND C.DiscountingSharedPercentage > 0
WHERE RARD.JobStepInstanceId = @JobStepInstanceId
GROUP BY RARD.ContractId
)
SELECT CD.ContractId,
DF.DiscountingId,
DC.DiscountingFinanceId,
DF.SharedPercentage,
DC.BookedResidual_Amount BookedResidual,
DC.ResidualBalance_Amount ResidualBalance,
DC.IncludeResidual,
DC.Id DiscountingContractId,
DF.PaymentAllocation,
ContractMaturityDate.MaturityDate,
DF.FunderId,
DF.LegalEntityId,
DF.InstrumentTypeId,
DF.LineOfBusinessId,
DF.CostCenterId,
DF.BranchId,
DF.DiscountingPayablesRemitToId PayableRemitToId,
D.CurrencyId,
DC.BookedResidual_Currency Currency,
DF.DiscountingInterestPayableCodeId InterestPayableCodeId,
DF.DiscountingPrincipalPayableCodeId PrincipalPayableCodeId,
CAST(NULL AS BIGINT) ResidualRepaymentId
INTO #ContractLevelInfo
FROM CTE_ContractsWithDiscounting CD
INNER JOIN DiscountingContracts DC ON CD.ContractId = DC.ContractId
INNER JOIN DiscountingFinances DF ON DC.DiscountingFinanceId = DF.Id AND DF.IsCurrent = 1 AND DF.Tied = 1
INNER JOIN Discountings D ON DF.DiscountingId = D.Id
LEFT JOIN
(
SELECT DISTINCT CD.ContractId,LFD. MaturityDate
FROM CTE_ContractsWithDiscounting CD
INNER JOIN LeaseFinances LF ON CD.ContractId = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
) AS ContractMaturityDate ON CD.ContractId = ContractMaturityDate.ContractId
;WITH CTE_ServicingDetails AS
(
SELECT C.DiscountingFinanceId,
DS.Collected,
DS.PerfectPay,
DS.EffectiveDate,
ROW_NUMBER() OVER (PARTITION BY C.DiscountingFinanceId ORDER BY DS.EffectiveDate) RowNumber
FROM (SELECT DISTINCT DiscountingFinanceId FROM #ContractLevelInfo) C
JOIN DiscountingServicingDetails DS ON C.DiscountingFinanceId = DS.DiscountingFinanceId AND DS.IsActive = 1
)
SELECT C.DiscountingId,
C.DiscountingFinanceId,
DRS.Id RepaymentScheduleId,
DRS.StartDate,
DRS.EndDate,
DRS.DueDate,
DRS.Principal_Amount Principal,
DRS.Interest_Amount Interest,
DRS.PrincipalProcessed_Amount PrincipalProcessed,
DRS.InterestProcessed_Amount InterestProcessed
INTO #RepaymentScheduleDetails
FROM (SELECT DISTINCT DiscountingId, DiscountingFinanceId FROM #ContractLevelInfo) C
INNER JOIN DiscountingRepaymentSchedules DRS ON C.DiscountingFinanceId = DRS.DiscountingFinanceId AND DRS.IsActive=1
INNER JOIN CTE_ServicingDetails ServicingDetail ON C.DiscountingFinanceId = ServicingDetail.DiscountingFinanceId
LEFT JOIN CTE_ServicingDetails NextServicingDetail ON ServicingDetail.DiscountingFinanceId = NextServicingDetail.DiscountingFinanceId AND ServicingDetail.RowNumber + 1 = NextServicingDetail.RowNumber
WHERE ServicingDetail.EffectiveDate <= DRS.DueDate
AND (NextServicingDetail.EffectiveDate IS NULL OR DRS.DueDate < NextServicingDetail.EffectiveDate)
AND ServicingDetail.Collected = 1 AND ServicingDetail.PerfectPay = @YesNoValues_No
AND (DRS.Principal_Amount <> DRS.PrincipalProcessed_Amount OR DRS.Interest_Amount <> DRS.InterestProcessed_Amount)
INSERT INTO ReceiptDiscountingRepaymentSchedules_Extract(DiscountingId, DiscountingFinanceId, RepaymentScheduleId, StartDate, EndDate, DueDate, Principal, Interest, PrincipalProcessed, InterestProcessed, TiedContractPaymentDetailId, ContractId, PaymentScheduleId, SharedAmount, Balance, TiedPaymentAmountUtilized, JobStepInstanceId, CreatedById, CreatedTime)
SELECT RS.DiscountingId,
RS.DiscountingFinanceId,
RS.RepaymentScheduleId,
RS.StartDate,
RS.EndDate,
RS.DueDate,
RS.Principal,
RS.Interest,
RS.PrincipalProcessed,
RS.InterestProcessed,
TC.Id TiedContractPaymentDetailId,
C.ContractId,
TC.PaymentScheduleId,
TC.SharedAmount_Amount SharedAmount,
TC.Balance_Amount Balance,
0,
@JobStepInstanceId,
@CreatedById,
@CreatedTime
FROM #RepaymentScheduleDetails RS
INNER JOIN #ContractLevelInfo C ON RS.DiscountingFinanceId = C.DiscountingFinanceId
LEFT JOIN TiedContractPaymentDetails TC ON C.ContractId = TC.ContractId AND RS.RepaymentScheduleId = TC.DiscountingRepaymentScheduleId AND TC.IsActive = 1
--Repayment ScheduleIds of Normal Receivables
UPDATE ReceiptReceivableDetails_Extract
SET IsTiedToDiscounting = 1
FROM ReceiptReceivableDetails_Extract RARD
INNER JOIN ReceiptDiscountingRepaymentSchedules_Extract RS ON RARD.PaymentScheduleId = RS.PaymentScheduleId AND RARD.ContractId = RS.ContractId
WHERE RARD.JobStepInstanceId = @JobStepInstanceId
AND RS.JobStepInstanceId = @JobStepInstanceId
--Repayment ScheduleIds of Buyout Receivables
;WITH CTE_RepaymentScheduleDetails AS
(
SELECT RS.DiscountingFinanceId,
RS.RepaymentScheduleId,
RS.DueDate,
ROW_NUMBER() OVER (PARTITION BY RS.DiscountingFinanceId ORDER BY RS.DueDate) RowNumber
FROM ReceiptDiscountingRepaymentSchedules_Extract RS
WHERE EXISTS (SELECT 1 FROM #ContractLevelInfo C
WHERE RS.DiscountingFinanceId = C.DiscountingFinanceId AND C.IncludeResidual = 1 AND C.BookedResidual != 0 AND C.ResidualBalance != 0) AND RS.JobStepInstanceId = @JobStepInstanceId
)
UPDATE #ContractLevelInfo
SET ResidualRepaymentId = CurrentRepaymentDetail.RepaymentScheduleId
FROM CTE_RepaymentScheduleDetails CurrentRepaymentDetail
INNER JOIN #ContractLevelInfo C ON C.DiscountingFinanceId = CurrentRepaymentDetail.DiscountingFinanceId AND C.IncludeResidual = 1 AND C.BookedResidual != 0 AND C.ResidualBalance != 0
LEFT JOIN CTE_RepaymentScheduleDetails PreviousRepaymentDetail ON CurrentRepaymentDetail.DiscountingFinanceId = PreviousRepaymentDetail.DiscountingFinanceId AND CurrentRepaymentDetail.RowNumber = PreviousRepaymentDetail.RowNumber + 1
WHERE (PreviousRepaymentDetail.DueDate IS NULL OR PreviousRepaymentDetail.DueDate < C.MaturityDate)
AND C.MaturityDate <= CurrentRepaymentDetail.DueDate
--Final Contract Level Information after all Filters
;WITH CTE_DistinctDiscountingFinanceIds AS
(
SELECT DISTINCT DiscountingFinanceId
FROM ReceiptDiscountingRepaymentSchedules_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO ReceiptDiscountingContracts_Extract(ContractId, DiscountingId, DiscountingFinanceId, SharedPercentage, BookedResidual, ResidualBalance, IncludeResidual, DiscountingContractId, PaymentAllocation,	MaturityDate, FunderId, LegalEntityId, InstrumentTypeId, LineOfBusinessId, CostCenterId, BranchId, PayableRemitToId, CurrencyId, Currency, InterestPayableCodeId, PrincipalPayableCodeId, ResidualRepaymentId, ResidualAmountUtilized, JobStepInstanceId, CreatedById, CreatedTime)
SELECT C.ContractId,
C.DiscountingId,
C.DiscountingFinanceId,
C.SharedPercentage,
C.BookedResidual,
C.ResidualBalance,
C.IncludeResidual,
C.DiscountingContractId,
C.PaymentAllocation,
C.MaturityDate,
C.FunderId,
C.LegalEntityId,
C.InstrumentTypeId,
C.LineOfBusinessId,
C.CostCenterId,
C.BranchId,
C.PayableRemitToId,
C.CurrencyId,
C.Currency,
C.InterestPayableCodeId,
C.PrincipalPayableCodeId,
C.ResidualRepaymentId,
0,
@JobStepInstanceId,
@CreatedById,
@CreatedTime
FROM #ContractLevelInfo C
INNER JOIN CTE_DistinctDiscountingFinanceIds DF ON C.DiscountingFinanceId = DF.DiscountingFinanceId
UPDATE ReceiptReceivableDetails_Extract
SET IsTiedToDiscounting = 1
FROM ReceiptDiscountingContracts_Extract C
INNER JOIN ReceiptReceivableDetails_Extract RARD ON RARD.JobStepInstanceId = @JobStepInstanceId
AND RARD.JobStepInstanceId = C.JobStepInstanceId AND C.ContractId = RARD.ContractId
AND C.ResidualRepaymentId IS NOT NULL AND RARD.ReceivableType = @ReceivableTypeValues_BuyOut
;WITH CTE_PayOffDetails AS
(
SELECT DISTINCT P.PayoffEffectiveDate,LF.ContractId FROM Payoffs P
JOIN LeaseFinances LF ON P.LeaseFinanceId = LF.Id
JOIN #ContractLevelInfo CI ON LF.ContractId = CI.ContractId
JOIN  ReceiptReceivableDetails_Extract c  ON  LF.ContractId = c.ContractId
WHERE CI.MaturityDate = P.PayoffEffectiveDate
)
,CTE_DiscountingRepaymentScheduleDetails AS
(
SELECT RS.StartDate,RS.EndDate,RS.DueDate,C.ContractId, ROW_NUMBER () OVER (Partition by C.ContractId order by RS.DueDate) as RowNumber FROM #RepaymentScheduleDetails RS
 JOIN #ContractLevelInfo C ON RS.DiscountingFinanceId = C.DiscountingFinanceId
 WHERE C.IncludeResidual = 1 AND c.MaturityDate < RS.DueDate
Group by RS.StartDate,RS.EndDate,RS.DueDate,C.ContractId
)
UPDATE ReceiptReceivableDetails_Extract
SET IsTiedToDiscounting = 0
FROM ReceiptReceivableDetails_Extract R
LEFT JOIN CTE_PayOffDetails PD ON R.ContractId = PD.ContractId
LEFT JOIN CTE_DiscountingRepaymentScheduleDetails DRS ON R.ContractId = DRS.ContractId and DRS.RowNumber=1
WHERE R.JobStepInstanceId = @JobStepInstanceId AND R.ReceivableType = @ReceivableTypeValues_BuyOut 
AND (PD.ContractId IS NULL OR (PD.ContractId IS NOT NULL AND DRS.ContractId IS NOT NULL AND (PD.PayoffEffectiveDate < DRS.StartDate OR PD.PayoffEffectiveDate > DRS.EndDate)))
END

GO
