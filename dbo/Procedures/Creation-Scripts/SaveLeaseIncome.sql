SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveLeaseIncome]
(
@LeaseIncome LeaseIncomeScheduleToSave READONLY,
@CurrencyCode NVARCHAR(3),
@CreatedByUserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #InsertedIncome
(
Id BIGINT,
IncomeDate DATETIME
)
INSERT INTO LeaseIncomeSchedules
([IncomeDate]
,[IncomeType]
,[IsGLPosted]
,[AccountingTreatment]
,[IsAccounting]
,[IsSchedule]
,[LeaseModificationType]
,[LeaseModificationID]
,[IsLessorOwned]
,[IsNonAccrual]
,[BeginNetBookValue_Amount]
,[BeginNetBookValue_Currency]
,[EndNetBookValue_Amount]
,[EndNetBookValue_Currency]
,[Income_Amount]
,[Income_Currency]
,[IncomeAccrued_Amount]
,[IncomeAccrued_Currency]
,[IncomeBalance_Amount]
,[IncomeBalance_Currency]
,[RentalIncome_Amount]
,[RentalIncome_Currency]
,[DeferredRentalIncome_Amount]
,[DeferredRentalIncome_Currency]
,[ResidualIncome_Amount]
,[ResidualIncome_Currency]
,[ResidualIncomeBalance_Amount]
,[ResidualIncomeBalance_Currency]
,[Payment_Amount]
,[Payment_Currency]
,[CreatedById]
,[CreatedTime]
,[LeaseFinanceId]
,[OperatingBeginNetBookValue_Amount]
,[OperatingEndNetBookValue_Amount]
,[Depreciation_Amount]
,[OperatingBeginNetBookValue_Currency]
,[OperatingEndNetBookValue_Currency]
,[Depreciation_Currency]
,[AdjustmentEntry]
,[IsReclassOTP])
OUTPUT INSERTED.Id, INSERTED.IncomeDate INTO #InsertedIncome
SELECT
IncomeDate
,IncomeType
,IsGLPosted
,AccountingTreatment
,IsAccounting
,IsSchedule
,LeaseModificationType
,LeaseModificationID
,IsLessorOwned
,IsNonAccrual
,BeginNetBookValue
,@CurrencyCode
,EndNetBookValue
,@CurrencyCode
,Income
,@CurrencyCode
,IncomeAccrued
,@CurrencyCode
,IncomeBalance
,@CurrencyCode
,RentalIncome
,@CurrencyCode
,DeferredRentalIncome
,@CurrencyCode
,ResidualIncome
,@CurrencyCode
,ResidualIncomeBalance
,@CurrencyCode
,Payment
,@CurrencyCode
,@CreatedByUserId
,@CreatedTime
,LeaseFinanceId
,OperatingBeginNetBookValue
,OperatingEndNetBookValue
,Depreciation
,@CurrencyCode
,@CurrencyCode
,@CurrencyCode
,0
,0
FROM
@LeaseIncome
SELECT
Id
,IncomeDate
FROM
#InsertedIncome
SET NOCOUNT OFF;
END

GO
