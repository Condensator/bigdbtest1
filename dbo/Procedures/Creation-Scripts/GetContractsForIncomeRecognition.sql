SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[GetContractsForIncomeRecognition]
(
@EntityType NVARCHAR(30),
@FilterOption NVARCHAR(10),
@CustomerId BIGINT,
@ContractId BIGINT,
@ProcessThroughDate DATETIMEOFFSET,
@LegalEntityIds LEIdList READONLY,
@ConsiderFiscalCalendar BIT
)
AS
BEGIN
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
DECLARE @SQLQuery NVARCHAR(MAX)
DECLARE @FilterConditions NVARCHAR(MAX)
SET @FilterConditions = ' '
IF @EntityType = 'Customer' AND @FilterOption = 'One'
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'CustomerId = @CustomerId'
END
ELSE IF @EntityType = 'Lease'
BEGIN
IF @FilterOption = 'All'
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'ContractType = ''Lease'''
END
ELSE
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'ContractType = ''Lease'' AND ContractId = @ContractId'
END
END
ELSE IF @EntityType = 'Loan'
BEGIN
IF @FilterOption = 'All'
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  '(ContractType = ''Loan'' OR ContractType = ''ProgressLoan'')'
END
ELSE
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  '(ContractType = ''Loan'' OR ContractType = ''ProgressLoan'') AND ContractId = @ContractId'
END
END
ELSE IF @EntityType = 'LeveragedLease'
BEGIN
IF @FilterOption = 'All'
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'ContractType = ''LeveragedLease'''
END
ELSE
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'ContractType = ''LeveragedLease'' AND ContractId = @ContractId'
END
END
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'EXISTS (SELECT LEId FROM @LegalEntityIds WHERE LEId=LegalEntityId)'
SET @SQLQuery = '
DECLARE @True BIT
DECLARE @False BIT
DECLARE @ContractTerminatedStatus NVARCHAR(MAX)
DECLARE @ContractChargeOffStatus NVARCHAR(MAX)
DECLARE @ContractCommencedStatus NVARCHAR(MAX)
DECLARE @ContractSuspendedStatus NVARCHAR(MAX)
SET @ContractTerminatedStatus=''Terminated''
SET @ContractCommencedStatus=''Commenced''
SET @ContractChargeOffStatus=''ChargedOff''
SET @ContractSuspendedStatus=''Suspended''
SET @True = 1
SET @False = 0
SELECT
LegalEntities.Id LegalEntityId,
MIN(FiscalEndDate) PostDate,
MIN(CalendarEndDate) ProcessThroughDate
INTO #FiscalCalendarInfo
FROM LegalEntities
JOIN BusinessCalendars ON LegalEntities.BusinessCalendarId = BusinessCalendars.Id
JOIN FiscalCalendars ON BusinessCalendars.Id = FiscalCalendars.BusinessCalendarId
WHERE FiscalCalendars.FiscalEndDate >= @ProcessThroughDate
GROUP BY LegalEntities.Id
;WITH ALLContracts
AS
(
SELECT
Contracts.Id AS ContractId
,Contracts.ContractType
,LoanFinanceId = Null
,LeaseFinanceId = LeaseFinances.Id
,LeveragedLeaseId = null
,LegalEntityId = LeaseFinances.LegalEntityId
,CustomerId = LeaseFinances.CustomerId
,InstrumentTypeId = LeaseFinances.InstrumentTypeId
,LineofBusinessId = LeaseFinances.LineofBusinessId
,SequenceNumber = contracts.SequenceNumber
,IsLease = @True
,IsLeveragedLease = @False
,#FiscalCalendarInfo.PostDate
,#FiscalCalendarInfo.ProcessThroughDate
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE Contracts.ContractType = ''Lease''
AND LeaseFinances.IsCurrent = 1
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION ALL
SELECT
Contracts.Id AS ContractId
,Contracts.ContractType
,LoanFinanceId = LoanFinances.Id
,LeaseFinanceId = null
,LeveragedLeaseId = null
,LegalEntityId = LoanFinances.LegalEntityId
,CustomerId = LoanFinances.CustomerId
,InstrumentTypeId = LoanFinances.InstrumentTypeId
,LineofBusinessId = LoanFinances.LineofBusinessId
,SequenceNumber = contracts.SequenceNumber
,IsLease = @False
,IsLeveragedLease = @False
,#FiscalCalendarInfo.PostDate
,#FiscalCalendarInfo.ProcessThroughDate
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE (Contracts.ContractType = ''Loan'' OR Contracts.ContractType =''ProgressLoan'')
AND LoanFinances.IsCurrent = 1
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION ALL
SELECT
Contracts.Id AS ContractId
,Contracts.ContractType
,LoanFinanceId = null
,LeaseFinanceId = null
,LeveragedLeaseId = LeveragedLeases.Id
,LegalEntityId = LeveragedLeases.LegalEntityId
,CustomerId = LeveragedLeases.CustomerId
,InstrumentTypeId = LeveragedLeases.InstrumentTypeId
,LineofBusinessId = LeveragedLeases.LineofBusinessId
,SequenceNumber = contracts.SequenceNumber
,IsLease = @False
,IsLeveragedLease =  @True
,#FiscalCalendarInfo.PostDate
,#FiscalCalendarInfo.ProcessThroughDate
FROM Contracts
INNER JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId
INNER JOIN LegalEntities ON LeveragedLeases.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE Contracts.ContractType = ''LeveragedLease''
AND LeveragedLeases.IsCurrent = 1
AND ((LeveragedLeases.Status!=@ContractSuspendedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
)
,FilteredContracts
AS
(
SELECT
ContractId
,ContractType
,LoanFinanceId
,LeaseFinanceId
,LeveragedLeaseId
,LegalEntityId
,CustomerId
,InstrumentTypeId
,LineofBusinessId
,SequenceNumber
,IsLease
,IsLeveragedLease
,PostDate
,ProcessThroughDate
FROM ALLContracts
FILTERCONDITIONS
)
,CTE_CashBasedOTPEntriesForLease
AS
(
Select
ContractId
,LeaseIncomeScheduleId
,IncomeDate
,AccountingTreatment
,IsReclassOTP
,IsGLPosted
,LeaseIncomeDateOrder
From
(
Select
ContractId=LeaseFinances.ContractId
,LeaseIncomeScheduleId=LeaseIncomeSchedules.Id
,IncomeDate=LeaseIncomeSchedules.IncomeDate
,AccountingTreatment=LeaseIncomeSchedules.AccountingTreatment
,IsReclassOTP=LeaseIncomeSchedules.IsReclassOTP
,IsGLPosted=LeaseIncomeSchedules.IsGLPosted
,LeaseIncomeDateOrder=ROw_NUmber() OVER(Partition By LeaseFinances.ContractId ORDER BY IncomeDate)
from LeaseIncomeSchedules
Inner Join LeaseFinances On LeaseIncomeSchedules.LeaseFinanceId=LeaseFinances.Id
Inner Join Contracts On Contracts.Id=LeaseFinances.ContractId
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
And ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
And LeaseIncomeSchedules.IncomeType=''OverTerm''
And LeaseIncomeSchedules.IsAccounting=1
And LeaseIncomeSchedules.AdjustmentEntry=0
And ((@ConsiderFiscalCalendar = 0 AND IncomeDate<=@ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
Inner Join LeaseFinanceDetails On LeaseFinanceDetails.Id=LeaseFinances.Id
And LeaseFinanceDetails.LeaseContractType=''DirectFinance''
)As Temp_LeaseIncomeSchedules
Where
LeaseIncomeDateOrder=1
AND AccountingTreatment=''CashBased''
AND IsReclassOTP=0
)
,ContractsWithIncome
AS
(
SELECT
ContractId = Con.Id
FROM
(
SELECT
Contracts.Id
FROM LoanIncomeSchedules
INNER JOIN LoanFinances ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND LoanIncomeSchedules.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND LoanIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND LoanIncomeSchedules.IsGLPosted = 0
AND LoanIncomeSchedules.AdjustmentEntry=0
AND LoanIncomeSchedules.IsAccounting=1
-- AND LoanIncomeSchedules.InterestAccrued_Amount !=0
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM LoanCapitalizedInterests
INNER JOIN LoanFinances ON LoanCapitalizedInterests.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND LoanCapitalizedInterests.CapitalizedDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND LoanCapitalizedInterests.CapitalizedDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND LoanCapitalizedInterests.GLJournalId = null
AND LoanCapitalizedInterests.IsActive=1
-- AND LoanCapitalizedInterests.Amount_Amount!=0
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM BlendedIncomeSchedules
INNER JOIN LoanFinances ON BlendedIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND BlendedIncomeSchedules.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND BlendedIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND BlendedIncomeSchedules.PostDate IS NULL
AND BlendedIncomeSchedules.IsAccounting=1
AND BlendedIncomeSchedules.AdjustmentEntry =0
-- AND BlendedIncomeSchedules.Income_Amount !=0
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LoanBlendedItems ON BlendedItems.Id = LoanBlendedItems.BlendedItemId
INNER JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LoanFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND BlendedItemDetails.DueDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND BlendedItemDetails.DueDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND BlendedItemDetails.IsGLPosted = 0
AND BlendedItems.IsActive=1
AND BlendedItemDetails.IsActive=1
-- AND BlendedItemDetails.Amount_Amount!=0
AND (BlendedItems.Occurrence=''Recurring'' OR BlendedItems.BookRecognitionMode=''Accrete'')
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION ALL
SELECT
Contracts.Id
FROM LeaseIncomeSchedules
INNER JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND LeaseIncomeSchedules.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND LeaseIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND LeaseIncomeSchedules.IsGLPosted = 0
AND LeaseIncomeSchedules.AdjustmentEntry=0
AND LeaseIncomeSchedules.IsAccounting=1
-- AND LeaseIncomeSchedules.Income_Amount !=0
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM LeaseFloatRateIncomes
INNER JOIN LeaseFinances ON LeaseFloatRateIncomes.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND LeaseFloatRateIncomes.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND LeaseFloatRateIncomes.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND LeaseFloatRateIncomes.IsGLPosted = 0
AND LeaseFloatRateIncomes.AdjustmentEntry=0
AND LeaseFloatRateIncomes.IsAccounting=1
-- AND LeaseFloatRateIncomes.CustomerIncomeAmount_Amount !=0
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId
INNER JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND BlendedItemDetails.DueDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND BlendedItemDetails.DueDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND BlendedItemDetails.IsGLPosted = 0
AND BlendedItems.IsActive=1
AND BlendedItemDetails.IsActive=1
-- AND BlendedItemDetails.Amount_Amount!=0
AND ( BlendedItems.Occurrence= ''Recurring'' OR BlendedItems.BookRecognitionMode =''Accrete'')
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION
SELECT
Contracts.Id
FROM BlendedIncomeSchedules
INNER JOIN LeaseFinances ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND BlendedIncomeSchedules.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND BlendedIncomeSchedules.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND BlendedIncomeSchedules.PostDate IS NULL
AND BlendedIncomeSchedules.IsAccounting=1
AND BlendedIncomeSchedules.AdjustmentEntry =0
-- AND BlendedIncomeSchedules.Income_Amount !=0
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION ALL
SELECT
Contracts.Id
FROM LeveragedLeaseAmorts
INNER JOIN LeveragedLeases ON LeveragedLeaseAmorts.LeveragedLeaseId = LeveragedLeases.Id
INNER JOIN Contracts on LeveragedLeases.ContractId = Contracts.Id
INNER JOIN LegalEntities ON LeveragedLeases.LegalEntityId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON LegalEntities.Id = #FiscalCalendarInfo.LegalEntityId
WHERE ((@ConsiderFiscalCalendar = 0 AND LeveragedLeaseAmorts.IncomeDate <= @ProcessThroughDate) OR (@ConsiderFiscalCalendar = 1 AND #FiscalCalendarInfo.LegalEntityId IS NOT NULL AND LeveragedLeaseAmorts.IncomeDate <= #FiscalCalendarInfo.ProcessThroughDate))
AND LeveragedLeaseAmorts.IsGLPosted = 0
AND LeveragedLeaseAmorts.IsActive=1
--AND LeveragedLeaseAmorts.PreTaxIncome_Amount !=0
AND ((LeveragedLeases.Status!=@ContractSuspendedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
GROUP BY Contracts.Id
UNION ALL
SELECT
DISTINCT Id=ContractId
FROM CTE_CashBasedOTPEntriesForLease
) Con GROUP BY Con.Id
)
SELECT
FilteredContracts.ContractId
,FilteredContracts.ContractType
,FilteredContracts.LoanFinanceId
,FilteredContracts.LeaseFinanceId
,FilteredContracts.LeveragedLeaseId
,FilteredContracts.LegalEntityId
,FilteredContracts.CustomerId
,FilteredContracts.InstrumentTypeId
,FilteredContracts.LineofBusinessId
,FilteredContracts.SequenceNumber
,FilteredContracts.IsLease
,FilteredContracts.IsLeveragedLease
,HasIncomeRecord = CASE WHEN ContractsWithIncome.ContractId IS NOT NULL THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END
,FilteredContracts.PostDate [FiscalPostDate]
,FilteredContracts.ProcessThroughDate [FiscalProcessThroughDate]
FROM FilteredContracts
LEFT JOIN ContractsWithIncome ON FilteredContracts.ContractId = ContractsWithIncome.ContractId
'
IF @FilterConditions IS NOT NULL
SET @SQLQuery = REPLACE(@SQLQuery, 'FILTERCONDITIONS', @FilterConditions )
ELSE
SET @SQLQuery = REPLACE(@SQLQuery, 'FILTERCONDITIONS', '' )
END
EXEC sp_executesql @SQLQuery, N'
@EntityType NVARCHAR(30)
,@FilterOption NVARCHAR(10)
,@CustomerId BIGINT
,@ContractId BIGINT
,@FilterConditions NVARCHAR(MAX)
,@ProcessThroughDate DATETIMEOFFSET
,@LegalEntityIds LEIdList READONLY
,@ConsiderFiscalCalendar BIT'
,@EntityType
,@FilterOption
,@CustomerId
,@ContractId
,@FilterConditions
,@ProcessThroughDate
,@LegalEntityIds
,@ConsiderFiscalCalendar

GO
