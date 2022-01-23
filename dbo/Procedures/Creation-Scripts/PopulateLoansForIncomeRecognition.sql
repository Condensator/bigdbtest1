SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PopulateLoansForIncomeRecognition] (
@EntityType NVARCHAR(30)
, @CreatedById BIGINT
, @CreatedTime DATETIMEOFFSET
, @FilterOption NVARCHAR(10)
, @CustomerId BIGINT
, @ContractId BIGINT
, @ProcessThroughDate DATE
, @PostDate DATE
, @LegalEntityIds IdList READONLY
, @ConsiderFiscalCalendar BIT
, @JobStepInstanceId BIGINT
, @AllFilterOption NVARCHAR(10)
, @OneFilterOption NVARCHAR(10)
, @CustomerEntityType NVARCHAR(15)
, @LoanEntityType NVARCHAR(10)
, @ProgressLoanEntityType NVARCHAR(15)
, @ContractTerminatedStatus NVARCHAR(15)
, @ContractChargeOffStatus NVARCHAR(15)
, @BlendedItemRecurringOccurrence NVARCHAR(15)
, @BlendedItemBookRecognitionMode NVARCHAR(15)
)
AS
BEGIN
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
DECLARE @True BIT = 1
DECLARE @False BIT = 0
DECLARE @LegalEntityOpenPeriodDetails TABLE
(
LegalEntityId BIGINT NOT NULL PRIMARY KEY,
LegalEntityName NVARCHAR(100),
FromDate DATE,
ToDate DATE,
IsPostDateValid BIT
)
SELECT LegalEntities.Id AS LegalEntityId
, LegalEntities.Name AS LegalEntityName
, MIN(FiscalEndDate) AS PostDate
, MIN(CalendarEndDate) AS ProcessThroughDate
INTO #FiscalCalendarInfo
FROM LegalEntities
JOIN BusinessCalendars ON LegalEntities.BusinessCalendarId = BusinessCalendars.Id
JOIN FiscalCalendars ON BusinessCalendars.Id = FiscalCalendars.BusinessCalendarId
WHERE FiscalCalendars.FiscalEndDate >= @ProcessThroughDate
GROUP BY LegalEntities.Id, LegalEntities.Name;
IF(@ConsiderFiscalCalendar = 1)
BEGIN
INSERT INTO @LegalEntityOpenPeriodDetails(LegalEntityId, LegalEntityName, FromDate, ToDate, IsPostDateValid)
SELECT fiscalCalendarInfo.LegalEntityId
, fiscalCalendarInfo.LegalEntityName
, glPeriod.FromDate AS FromDate
, glPeriod.ToDate AS ToDate
, IsPostDateValid = CASE WHEN (fiscalCalendarInfo.PostDate >= glPeriod.FromDate AND fiscalCalendarInfo.PostDate <= glPeriod.ToDate)							THEN @True
ELSE @False END
FROM #FiscalCalendarInfo AS fiscalCalendarInfo
JOIN GLFinancialOpenPeriods AS glPeriod ON glPeriod.LegalEntityId = fiscalCalendarInfo.legalEntityId
WHERE glPeriod.IsCurrent = @True;
END
ELSE
BEGIN
INSERT INTO @LegalEntityOpenPeriodDetails(LegalEntityId, LegalEntityName, FromDate, ToDate, IsPostDateValid)
SELECT legalEntity.Id AS LegalEntityId
, legalEntity.Name AS LegalEntityName
, glPeriod.FromDate AS FromDate
, glPeriod.ToDate AS ToDate
, IsPostDateValid = CASE WHEN (@PostDate >= glPeriod.FromDate AND @PostDate <= glPeriod.ToDate) THEN @True
ELSE @False END
FROM LegalEntities AS legalEntity
JOIN GLFinancialOpenPeriods AS glPeriod ON glPeriod.LegalEntityId = legalEntity.Id
WHERE glPeriod.IsCurrent = @True;
END
;WITH ALL_Loans
AS (
SELECT Contracts.Id AS ContractId
, LoanFinanceId = LoanFinances.Id
, LegalEntityId = LoanFinances.LegalEntityId
, CASE WHEN @ConsiderFiscalCalendar = 1 THEN #FiscalCalendarInfo.PostDate ELSE @PostDate END AS PostDate
, CASE WHEN @ConsiderFiscalCalendar = 1 THEN #FiscalCalendarInfo.ProcessThroughDate ELSE @ProcessThroughDate END AS ProcessThroughDate
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
JOIN @LegalEntityIds AS legalEntity ON LoanFinances.LegalEntityId = legalEntity.Id
JOIN Customers AS customer ON LoanFinances.CustomerId = customer.Id
LEFT JOIN #FiscalCalendarInfo ON legalEntity.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
Contracts.ContractType = @LoanEntityType
OR Contracts.ContractType = @ProgressLoanEntityType
)
AND LoanFinances.IsCurrent = @True
AND (
(LoanFinances.STATUS != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
AND (
@FilterOption = @AllFilterOption
OR (
@EntityType = @CustomerEntityType
AND @FilterOption = @OneFilterOption
AND customer.Id = @CustomerId
)
OR (
@EntityType = @LoanEntityType
AND @FilterOption = @OneFilterOption
AND Contracts.Id = @ContractId
)
)
)
, ContractsWithIncome
AS (
SELECT ContractId = Con.Id,
PostDate,
ProcessThroughDate
FROM (
SELECT Contracts.Id
, ALL_Loans.PostDate
, ALL_Loans.ProcessThroughDate
FROM Contracts
INNER JOIN ALL_Loans ON Contracts.Id = ALL_Loans.ContractId
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
INNER JOIN LoanIncomeSchedules ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendar = 0
AND LoanIncomeSchedules.IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendar = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND LoanIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND LoanIncomeSchedules.IsGLPosted = 0
AND LoanIncomeSchedules.AdjustmentEntry = 0
AND LoanIncomeSchedules.IsAccounting = 1
AND (
(LoanFinances.STATUS != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Loans.PostDate, ALL_Loans.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Loans.PostDate
, ALL_Loans.ProcessThroughDate
FROM LoanCapitalizedInterests
INNER JOIN ALL_Loans ON LoanCapitalizedInterests.LoanFinanceId = ALL_Loans.LoanFinanceId
INNER JOIN LoanFinances ON LoanCapitalizedInterests.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendar = 0
AND LoanCapitalizedInterests.CapitalizedDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendar = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND LoanCapitalizedInterests.CapitalizedDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND LoanCapitalizedInterests.GLJournalId = NULL
AND LoanCapitalizedInterests.IsActive = 1
-- AND LoanCapitalizedInterests.Amount_Amount!=0
AND (
(LoanFinances.STATUS != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Loans.PostDate
, ALL_Loans.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Loans.PostDate
, ALL_Loans.ProcessThroughDate
FROM BlendedIncomeSchedules
INNER JOIN ALL_Loans ON BlendedIncomeSchedules.LoanFinanceId = ALL_Loans.LoanFinanceId
INNER JOIN LoanFinances ON BlendedIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendar = 0
AND BlendedIncomeSchedules.IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendar = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND BlendedIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND BlendedIncomeSchedules.PostDate IS NULL
AND BlendedIncomeSchedules.IsAccounting = 1
AND BlendedIncomeSchedules.AdjustmentEntry = 0
AND (
(LoanFinances.STATUS != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Loans.PostDate, ALL_Loans.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Loans.PostDate
, ALL_Loans.ProcessThroughDate
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LoanBlendedItems ON BlendedItems.Id = LoanBlendedItems.BlendedItemId
INNER JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id
INNER JOIN ALL_Loans ON LoanFinances.Id = ALL_Loans.LoanFinanceId
INNER JOIN Contracts ON LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendar = 0
AND BlendedItemDetails.DueDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendar = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND BlendedItemDetails.DueDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND BlendedItemDetails.IsGLPosted = 0
AND BlendedItems.IsActive = 1
AND BlendedItemDetails.IsActive = 1
AND (
BlendedItems.Occurrence = @BlendedItemRecurringOccurrence
OR BlendedItems.BookRecognitionMode = @BlendedItemBookRecognitionMode
)
AND (
(LoanFinances.STATUS != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Loans.PostDate, ALL_Loans.ProcessThroughDate
) Con
GROUP BY Con.Id, Con.PostDate, Con.ProcessThroughDate
)
SELECT ContractId, PostDate, ProcessThroughDate
INTO #ContractsWithIncome FROM ContractsWithIncome
INSERT INTO LoanIncomeRecognitionJobExtracts (LoanFinanceId, JobStepInstanceId, CreatedById, CreatedTime, IsSubmitted, PostDate
, ProcessThroughDate)
SELECT  lf.Id, @JobStepInstanceId, @CreatedById, @CreatedTime, 0, c.PostDate, c.ProcessThroughDate
FROM #ContractsWithIncome c
INNER JOIN LoanFinances lf ON lf.ContractId = c.ContractId
INNER JOIN @LegalEntityOpenPeriodDetails legalEntityOpenPeriodDetail ON lf.LegalEntityId = legalEntityOpenPeriodDetail.LegalEntityId
WHERE lf.IsCurrent = @True AND legalEntityOpenPeriodDetail.IsPostDateValid = @True
SELECT Distinct legalEntityOpenPeriodDetail.LegalEntityId
, legalEntityOpenPeriodDetail.LegalEntityName
, legalEntityOpenPeriodDetail.FromDate
, legalEntityOpenPeriodDetail.ToDate
, legalEntityOpenPeriodDetail.IsPostDateValid
FROM @LegalEntityOpenPeriodDetails legalEntityOpenPeriodDetail
JOIN LoanFinances lf ON lf.LegalEntityId = legalEntityOpenPeriodDetail.LegalEntityId
INNER JOIN #ContractsWithIncome contractsWithIncome ON contractsWithIncome.ContractId = lf.ContractId
WHERE lf.IsCurrent = @True AND legalEntityOpenPeriodDetail.IsPostDateValid = @False
IF OBJECT_ID('tempdb.#ContractsWithIncome') IS NOT NULL
DROP TABLE #ContractsWithIncome
SET NOCOUNT OFF
SET ANSI_WARNINGS ON
END

GO
