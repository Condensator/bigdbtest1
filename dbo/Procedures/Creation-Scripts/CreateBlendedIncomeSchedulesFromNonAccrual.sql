SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateBlendedIncomeSchedulesFromNonAccrual]
(
@IncomeSchedules BlendedIncomesToCreate READONLY,
@UserId BIGINT,
@CurrencyCode NVARCHAR(3),
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
CREATE TABLE #IncomeScheduleTemp
(
IncomeScheduleId BIGINT,
UniqueId BIGINT,
NonAccrualPostDate DATE,
)
MERGE INTO BlendedIncomeSchedules
USING(Select
IncomeDate
,Income
,IncomeBalance
,EffectiveYield
,EffectiveInterest
,IsAccounting
,IsSchedule
,PostDate
,ReversalPostDate
,ModificationType
,ModificationId
,IsNonAccrual
,AdjustmentEntry
,LeaseFinanceId
,LoanFinanceId
,BlendedItemId
,NonAccrualPostDate
,UniqueId
,0 AS IsRecomputed FROM @IncomeSchedules)
AS BlendedIncomes ON 1=0
WHEN NOT MATCHED THEN
INSERT
(IncomeDate
,Income_Amount
,Income_Currency
,IncomeBalance_Amount
,IncomeBalance_Currency
,EffectiveYield
,EffectiveInterest_Amount
,EffectiveInterest_Currency
,IsAccounting
,IsSchedule
,PostDate
,ReversalPostDate
,ModificationType
,ModificationId
,IsNonAccrual
,AdjustmentEntry
,CreatedById
,CreatedTime
,LeaseFinanceId
,LoanFinanceId
,BlendedItemId
,IsRecomputed)
VALUES
( IncomeDate
,Income
,@CurrencyCode
,IncomeBalance
,@CurrencyCode
,EffectiveYield
,EffectiveInterest
,@CurrencyCode
,IsAccounting
,IsSchedule
,NonAccrualPostDate
,ReversalPostDate
,ModificationType
,ModificationId
,IsNonAccrual
,AdjustmentEntry
,@UserId
,@ModificationTime
,CASE WHEN LeaseFinanceId<>0 THEN LeaseFinanceId ELSE NULL END
,CASE WHEN LoanFinanceId<>0 THEN LoanFinanceId ELSE NULL END
,BlendedItemId
,0)
OUTPUT INSERTED.Id,BlendedIncomes.UniqueId,BlendedIncomes.NonAccrualPostDate INTO #IncomeScheduleTemp;
SELECT
IncomeScheduleId = IncomeScheduleId,
UniqueId = UniqueId,
PostDate = NonAccrualPostDate
FROM
#IncomeScheduleTemp
DROP TABLE #IncomeScheduleTemp;
END

GO
