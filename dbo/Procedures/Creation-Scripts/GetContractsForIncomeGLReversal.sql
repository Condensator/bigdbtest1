SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[GetContractsForIncomeGLReversal]
(
@EntityType NVARCHAR(30),
@FilterOption NVARCHAR(10),
@CustomerId BIGINT,
@ContractId BIGINT,
@AsOfDate DATETIMEOFFSET,
@LegalEntityIds LEIdListForInComeGLReversal READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
DECLARE @SQLQuery NVARCHAR(MAX)
DECLARE @FilterConditions NVARCHAR(MAX)
SET @FilterConditions = ' '

Declare @AsOfDate_Temp Date =@AsOfDate;

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
SET @FilterConditions = @FilterConditions +  'ContractType = ''Loan'' OR ContractType = ''ProgressLoan'''
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
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
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
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
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
FROM Contracts
INNER JOIN LeveragedLeases ON Contracts.Id = LeveragedLeases.ContractId
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
FROM ALLContracts
FILTERCONDITIONS
)
,CTE_CashBasedOTPEntriesForLease AS
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
And ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
And LeaseIncomeSchedules.IncomeType=''OverTerm''
And LeaseIncomeSchedules.IsAccounting=1
And LeaseIncomeSchedules.AdjustmentEntry=0
And IncomeDate>=@AsOfDate
Inner Join LeaseFinanceDetails On LeaseFinanceDetails.Id=LeaseFinances.Id
And LeaseFinanceDetails.LeaseContractType=''DirectFinance''
)As Temp_LeaseIncomeSchedules
Where
LeaseIncomeDateOrder=1
AND AccountingTreatment=''CashBased''
AND IsReclassOTP=1
)
,ContractsWithIncome
AS
(
SELECT
DISTINCT ContractId = Con.Id
FROM
(
SELECT
DISTINCT Contracts.Id
FROM LoanIncomeSchedules
INNER JOIN LoanFinances ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
WHERE LoanIncomeSchedules.IncomeDate >= @AsOfDate
AND LoanIncomeSchedules.IsGLPosted = 1
AND LoanIncomeSchedules.AdjustmentEntry=0
AND LoanIncomeSchedules.IsAccounting=1
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM LoanCapitalizedInterests
INNER JOIN LoanFinances ON LoanCapitalizedInterests.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
WHERE LoanCapitalizedInterests.CapitalizedDate > = @AsOfDate
AND LoanCapitalizedInterests.GLJournalId is not null
AND LoanCapitalizedInterests.IsActive=1
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM BlendedIncomeSchedules
INNER JOIN LoanFinances ON BlendedIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
WHERE BlendedIncomeSchedules.IncomeDate >= @AsOfDate
AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.IsAccounting=1
AND BlendedIncomeSchedules.AdjustmentEntry =0
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LoanBlendedItems ON BlendedItems.Id = LoanBlendedItems.BlendedItemId
INNER JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts on LoanFinances.ContractId = Contracts.Id
WHERE BlendedItemDetails.DueDate >= @AsOfDate
AND BlendedItemDetails.IsGLPosted = 1
AND BlendedItems.IsActive=1
AND BlendedItemDetails.IsActive=1
AND (BlendedItems.Occurrence=''Recurring'' OR BlendedItems.BookRecognitionMode=''Accrete'')
AND ((LoanFinances.Status!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION ALL
SELECT
DISTINCT Contracts.Id
FROM LeaseIncomeSchedules
INNER JOIN LeaseFinances ON LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
WHERE LeaseIncomeSchedules.IncomeDate >= @AsOfDate
AND LeaseIncomeSchedules.IsGLPosted = 1
AND LeaseIncomeSchedules.AdjustmentEntry=0
AND LeaseIncomeSchedules.IsAccounting=1
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM LeaseFloatRateIncomes
INNER JOIN LeaseFinances ON LeaseFloatRateIncomes.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
WHERE LeaseFloatRateIncomes.IncomeDate >= @AsOfDate
AND LeaseFloatRateIncomes.IsGLPosted = 1
AND LeaseFloatRateIncomes.AdjustmentEntry=0
AND LeaseFloatRateIncomes.IsAccounting=1
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM BlendedItemDetails
INNER JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BlendedItems.Id
INNER JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId
INNER JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
WHERE BlendedItemDetails.DueDate >= @AsOfDate
AND BlendedItemDetails.IsGLPosted = 1
AND BlendedItems.IsActive=1
AND BlendedItemDetails.IsActive=1
AND ( BlendedItems.Occurrence= ''Recurring'' OR BlendedItems.BookRecognitionMode =''Accrete'')
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION
SELECT
DISTINCT Contracts.Id
FROM BlendedIncomeSchedules
INNER JOIN LeaseFinances ON BlendedIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Contracts on LeaseFinances.ContractId = Contracts.Id
WHERE BlendedIncomeSchedules.IncomeDate >= @AsOfDate
AND BlendedIncomeSchedules.PostDate IS NOT NULL
AND BlendedIncomeSchedules.IsAccounting=1
AND BlendedIncomeSchedules.AdjustmentEntry =0
AND ((LeaseFinances.BookingStatus!=@ContractTerminatedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION ALL
SELECT
DISTINCT Contracts.Id
FROM LeveragedLeaseAmorts
INNER JOIN LeveragedLeases ON LeveragedLeaseAmorts.LeveragedLeaseId = LeveragedLeases.Id
INNER JOIN Contracts on LeveragedLeases.ContractId = Contracts.Id
WHERE LeveragedLeaseAmorts.IncomeDate >= @AsOfDate
AND LeveragedLeaseAmorts.IsGLPosted = 1
AND LeveragedLeaseAmorts.IsActive=1
AND ((LeveragedLeases.Status!=@ContractSuspendedStatus) OR (Contracts.ChargeOffStatus=@ContractChargeOffStatus))
UNION ALL
SELECT
DISTINCT Id=ContractId
FROM CTE_CashBasedOTPEntriesForLease
) Con
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
FROM FilteredContracts
LEFT JOIN ContractsWithIncome ON FilteredContracts.ContractId = ContractsWithIncome.ContractId
'
IF @FilterConditions IS NOT NULL
SET @SQLQuery = REPLACE(@SQLQuery, 'FILTERCONDITIONS', @FilterConditions )
ELSE
SET @SQLQuery = REPLACE(@SQLQuery, 'FILTERCONDITIONS', '' )
END
EXEC sp_executesql @SQLQuery,
N'
@EntityType NVARCHAR(30)
,@FilterOption NVARCHAR(10)
,@CustomerId BIGINT
,@ContractId BIGINT
,@FilterConditions NVARCHAR(MAX)
,@AsOfDate DATE
,@LegalEntityIds LEIdListForIncomeGLReversal READONLY'
,@EntityType
,@FilterOption
,@CustomerId
,@ContractId
,@FilterConditions
,@AsOfDate_Temp
,@LegalEntityIds

GO
