SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PopulateLeasesForIncomeRecognition] (
@EntityType NVARCHAR(30)
, @CreatedById BIGINT
, @CreatedTime DATETIMEOFFSET
, @FilterOption NVARCHAR(10)
, @CustomerId BIGINT
, @ContractId BIGINT
, @ProcessThroughDate DATE
, @PostDate DATE
, @JobRunDate DATE
, @LegalEntityIds IdList READONLY
, @ConsiderFiscalCalendarProcessThroughDate BIT
, @ConsiderFiscalCalendarPostDate BIT
, @JobStepInstanceId BIGINT
, @AllFilterOption NVARCHAR(10)
, @OneFilterOption NVARCHAR(10)
, @CustomerEntityType NVARCHAR(15)
, @LeaseEntityType NVARCHAR(10)
, @ContractTerminatedStatus NVARCHAR(15)
, @ContractChargeOffStatus NVARCHAR(15)
, @DirectFinanceLeaseContractType NVARCHAR(15)
, @OverTermIncomeType NVARCHAR(15)
, @CashBasedAccountingTreatment NVARCHAR(15)
, @BlendedItemRecurringOccurrence NVARCHAR(15)
, @BlendedItemBookRecognitionMode NVARCHAR(15)
, @ExcludeBackgroundProcessingPendingContracts BIT
)
AS
BEGIN
SET NOCOUNT ON
--SET ANSI_WARNINGS OFF

DECLARE @True BIT
DECLARE @False BIT
SET @True = 1
SET @False = 0
SELECT LegalEntities.Id LegalEntityId
, LegalEntities.Name LegalEntityName
, MIN(FiscalEndDate) PostDate
, MIN(CalendarEndDate) ProcessThroughDate
INTO #FiscalCalendarInfo
FROM LegalEntities
JOIN BusinessCalendars ON LegalEntities.BusinessCalendarId = BusinessCalendars.Id
JOIN FiscalCalendars ON BusinessCalendars.Id = FiscalCalendars.BusinessCalendarId
WHERE FiscalCalendars.FiscalEndDate >= @JobRunDate
GROUP BY LegalEntities.Id , LegalEntities.Name;
CREATE TABLE #LegalEntityOpenPeriodDetails
(
LegalEntityId BIGINT,
LegalEntityName NVARCHAR(100),
FromDate DATE,
ToDate DATE,
IsPostDateValid BIT,
PostDate DATE,
ProcessThroughDate DATE
);
IF (@ConsiderFiscalCalendarProcessThroughDate = @True OR @ConsiderFiscalCalendarPostDate = @True)
BEGIN
INSERT INTO #LegalEntityOpenPeriodDetails
SELECT fiscalCalendarInfo.LegalEntityId AS LegalEntityId
, fiscalCalendarInfo.LegalEntityName AS LegalEntityName
, glPeriod.FromDate AS FromDate
, glPeriod.ToDate AS ToDate
, IsPostDateValid = CASE WHEN @ConsiderFiscalCalendarPostDate = @False AND (@PostDate >= glPeriod.FromDate AND @PostDate <= glPeriod.ToDate) THEN @True 
						 WHEN @ConsiderFiscalCalendarPostDate = @True AND (fiscalCalendarInfo.PostDate >= glPeriod.FromDate AND fiscalCalendarInfo.PostDate <= glPeriod.ToDate) THEN @True
						 ELSE @False END
, PostDate = CASE WHEN @ConsiderFiscalCalendarPostDate = @False THEN @PostDate ELSE fiscalCalendarInfo.PostDate END
, ProcessThroughDate = CASE WHEN @ConsiderFiscalCalendarProcessThroughDate = @False THEN @ProcessThroughDate ELSE 
					   fiscalCalendarInfo.ProcessThroughDate END
FROM GLFinancialOpenPeriods AS glPeriod
JOIN #FiscalCalendarInfo AS fiscalCalendarInfo ON fiscalCalendarInfo.LegalEntityId = glPeriod.LegalEntityId
WHERE glPeriod.IsCurrent = @True;
END
ELSE
BEGIN
INSERT INTO #LegalEntityOpenPeriodDetails
SELECT legalEntity.Id AS LegalEntityId
, legalEntity.Name AS LegalEntityName
, glPeriod.FromDate AS FromDate
, glPeriod.ToDate AS ToDate
, IsPostDateValid = CASE WHEN (@PostDate >= glPeriod.FromDate AND @PostDate <= glPeriod.ToDate) THEN @True
ELSE @False END
, @PostDate AS PostDate
, @ProcessThroughDate AS ProcessThroughDate
FROM LegalEntities AS legalEntity
JOIN GLFinancialOpenPeriods AS glPeriod ON glPeriod.LegalEntityId = legalEntity.Id
WHERE glPeriod.IsCurrent = @True;
END
;WITH ALL_Leases
AS (
SELECT Contracts.Id AS ContractId
, LeaseFinanceId = LeaseFinances.Id
, LegalEntityId = LeaseFinances.LegalEntityId
, CASE WHEN @ConsiderFiscalCalendarPostDate = 1 THEN #FiscalCalendarInfo.PostDate ELSE @PostDate END AS PostDate
, CASE WHEN @ConsiderFiscalCalendarProcessThroughDate = 1 THEN #FiscalCalendarInfo.ProcessThroughDate ELSE @ProcessThroughDate END AS ProcessThroughDate
FROM LeaseFinances
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN @LegalEntityIds AS legalEntity ON LeaseFinances.LegalEntityId = legalEntity.Id
JOIN Customers AS customer ON LeaseFinances.CustomerId = customer.Id
LEFT JOIN #FiscalCalendarInfo ON legalEntity.Id = #FiscalCalendarInfo.LegalEntityId
WHERE LeaseFinances.IsCurrent = @True
AND (@ExcludeBackgroundProcessingPendingContracts = @False OR Contracts.BackgroundProcessingPending = @False)
AND (
(LeaseFinances.BookingStatus != @ContractTerminatedStatus)
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
@EntityType = @LeaseEntityType
AND @FilterOption = @OneFilterOption
AND Contracts.Id = @ContractId
)
)
)
, CashBasedOTPEntriesForLease
AS (
SELECT ContractId = ALL_Leases.ContractId
, ALL_Leases.LeaseFinanceId
, ALL_Leases.PostDate
, ALL_Leases.ProcessThroughDate
FROM LeaseIncomeSchedules
JOIN ALL_Leases ON LeaseIncomeSchedules.LeaseFinanceId = ALL_Leases.LeaseFinanceId
JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id = ALL_Leases.LeaseFinanceId
WHERE LeaseIncomeSchedules.IncomeType = @OverTermIncomeType
AND LeaseIncomeSchedules.IsAccounting = 1
AND LeaseIncomeSchedules.AdjustmentEntry = 0
AND (
(
@ConsiderFiscalCalendarProcessThroughDate = 0
AND IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendarProcessThroughDate = 1
AND ALL_Leases.LegalEntityId IS NOT NULL
AND IncomeDate <= ALL_Leases.ProcessThroughDate
)
)
AND AccountingTreatment = @CashBasedAccountingTreatment
AND IsReclassOTP = 0
)
, ContractsWithIncome
AS (
SELECT ContractId = Con.Id
, PostDate = Con.PostDate
, ProcessThroughDate = Con.ProcessThroughDate
FROM (
SELECT Contracts.Id
, ALL_Leases.PostDate
, ALL_Leases.ProcessThroughDate
FROM Contracts
INNER JOIN ALL_Leases ON Contracts.Id = ALL_Leases.ContractId
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LeaseIncomeSchedules ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendarProcessThroughDate = 0
AND LeaseIncomeSchedules.IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendarProcessThroughDate = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND LeaseIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND LeaseIncomeSchedules.IsGLPosted = 0
AND LeaseIncomeSchedules.AdjustmentEntry = 0
AND LeaseIncomeSchedules.IsAccounting = 1
-- AND LeaseIncomeSchedules.Income_Amount !=0
AND (
(LeaseFinances.BookingStatus != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Leases.PostDate, ALL_Leases.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Leases.PostDate
, ALL_Leases.ProcessThroughDate
FROM LeaseFloatRateIncomes
JOIN ALL_Leases ON LeaseFloatRateIncomes.LeaseFinanceId = ALL_Leases.LeaseFinanceId
INNER JOIN LeaseFinances ON LeaseFloatRateIncomes.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendarProcessThroughDate = 0
AND LeaseFloatRateIncomes.IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendarProcessThroughDate = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND LeaseFloatRateIncomes.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND LeaseFloatRateIncomes.IsGLPosted = 0
AND LeaseFloatRateIncomes.AdjustmentEntry = 0
AND LeaseFloatRateIncomes.IsAccounting = 1
-- AND LeaseFloatRateIncomes.CustomerIncomeAmount_Amount !=0
AND (
(LeaseFinances.BookingStatus != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Leases.PostDate, ALL_Leases.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Leases.PostDate
, ALL_Leases.ProcessThroughDate
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId
INNER JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id
INNER JOIN ALL_Leases ON LeaseFinances.Id = ALL_Leases.LeaseFinanceId
INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendarProcessThroughDate = 0
AND BlendedItemDetails.DueDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendarProcessThroughDate = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND BlendedItemDetails.DueDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND BlendedItemDetails.IsGLPosted = 0
AND BlendedItems.IsActive = 1
AND BlendedItemDetails.IsActive = 1
-- AND BlendedItemDetails.Amount_Amount!=0
AND (
BlendedItems.Occurrence = @BlendedItemRecurringOccurrence
OR BlendedItems.BookRecognitionMode = @BlendedItemBookRecognitionMode
)
AND (
(LeaseFinances.BookingStatus != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Leases.PostDate, ALL_Leases.ProcessThroughDate
UNION
SELECT Contracts.Id
, ALL_Leases.PostDate
, ALL_Leases.ProcessThroughDate
FROM BlendedIncomeSchedules
INNER JOIN LeaseFinances ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
INNER JOIN ALL_Leases ON LeaseFinances.Id = ALL_Leases.LeaseFinanceId
INNER JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (
(
@ConsiderFiscalCalendarProcessThroughDate = 0
AND BlendedIncomeSchedules.IncomeDate <= @ProcessThroughDate
)
OR (
@ConsiderFiscalCalendarProcessThroughDate = 1
AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL
AND BlendedIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate
)
)
AND BlendedIncomeSchedules.PostDate IS NULL
AND BlendedIncomeSchedules.IsAccounting = 1
AND BlendedIncomeSchedules.AdjustmentEntry = 0
-- AND BlendedIncomeSchedules.Income_Amount !=0
AND (
(LeaseFinances.BookingStatus != @ContractTerminatedStatus)
OR (Contracts.ChargeOffStatus = @ContractChargeOffStatus)
)
GROUP BY Contracts.Id, ALL_Leases.PostDate, ALL_Leases.ProcessThroughDate
UNION ALL
SELECT DISTINCT Id = ContractId, PostDate, ProcessThroughDate
FROM CashBasedOTPEntriesForLease
) Con
GROUP BY Con.Id, Con.PostDate, Con.ProcessThroughDate
)
SELECT ContractId, PostDate, ProcessThroughDate INTO #ContractsWithIncome FROM ContractsWithIncome
INSERT INTO LeaseIncomeRecognitionJob_Extracts (
LeaseFinanceId
, JobStepInstanceId
--, CreatedById
--, CreatedTime
, IsSubmitted
, PostDate
, ProcessThroughDate
, AssetCount
)
SELECT  lf.Id 
, @JobStepInstanceId
--, @CreatedById
--, @CreatedTime
, 0
, legalEntityOpenPeriodDetail.PostDate
, legalEntityOpenPeriodDetail.ProcessThroughDate
, count(*) AssetCount
FROM #ContractsWithIncome c
INNER JOIN LeaseFinances lf ON lf.ContractId = c.ContractId
INNER JOIN LeaseAssets LA ON lf.Id = LA.LeaseFinanceId
INNER JOIN #LegalEntityOpenPeriodDetails legalEntityOpenPeriodDetail ON lf.LegalEntityId = legalEntityOpenPeriodDetail.LegalEntityId
where lf.IsCurrent = @True 
AND legalEntityOpenPeriodDetail.IsPostDateValid = @True
AND (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL)
GROUP BY lf.Id, legalEntityOpenPeriodDetail.PostDate, legalEntityOpenPeriodDetail.ProcessThroughDate

SELECT DISTINCT legalEntityOpenPeriodDetail.LegalEntityId  
, legalEntityOpenPeriodDetail.LegalEntityName 
, legalEntityOpenPeriodDetail.FromDate 
, legalEntityOpenPeriodDetail.ToDate 
, legalEntityOpenPeriodDetail.IsPostDateValid 
FROM #LegalEntityOpenPeriodDetails legalEntityOpenPeriodDetail
JOIN LeaseFinances lf ON lf.LegalEntityId = legalEntityOpenPeriodDetail.LegalEntityId
INNER JOIN #ContractsWithIncome contractsWithIncome ON contractsWithIncome.ContractId = lf.ContractId
WHERE lf.IsCurrent = @True AND legalEntityOpenPeriodDetail.IsPostDateValid = @False

IF OBJECT_ID('tempDB.#LegalEntityOpenPeriodDetails') IS NOT NULL
DROP TABLE #LegalEntityOpenPeriodDetails
IF OBJECT_ID('tempDB.#ContractsWithIncome') IS NOT NULL
DROP TABLE #ContractsWithIncome
IF OBJECT_ID('tempDB.#FiscalCalendarInfo') IS NOT NULL
DROP TABLE #FiscalCalendarInfo
SET NOCOUNT OFF
--SET ANSI_WARNINGS ON
END

GO
