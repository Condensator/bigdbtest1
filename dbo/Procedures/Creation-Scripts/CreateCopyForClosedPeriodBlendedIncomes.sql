SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateCopyForClosedPeriodBlendedIncomes]
(
@IncomeSchedules BlendedIncomesToClone READONLY,
@ModificationType NVARCHAR(50),
@ModificationId BIGINT,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET,
@IsNonAccrual BIT,
@IsLease BIT
)
AS
BEGIN
SET NOCOUNT ON
INSERT INTO BlendedIncomeSchedules
(
IncomeDate
,Income_Amount
,Income_Currency
,IncomeBalance_Amount
,IncomeBalance_Currency
,EffectiveYield
,EffectiveInterest_Amount
,EffectiveInterest_Currency
,IsAccounting
,IsSchedule
,ModificationType
,ModificationId
,IsNonAccrual
,AdjustmentEntry
,CreatedById
,CreatedTime
,LeaseFinanceId
,LoanFinanceId
,BlendedItemId
,IsRecomputed
)
SELECT
IncomeDate
,Income_Amount
,Income_Currency
,IncomeBalance_Amount
,IncomeBalance_Currency
,EffectiveYield
,EffectiveInterest_Amount
,EffectiveInterest_Currency
,CASE WHEN @IsLease = 1 THEN 0 ELSE IsAccounting END
,1
,@ModificationType
,@ModificationId
,@IsNonAccrual
,0
,@UserId
,@ModificationTime
,LeaseFinanceId
,LoanFinanceId
,BlendedItemId
,IsRecomputed
FROM BlendedIncomeSchedules BIS
JOIN @IncomeSchedules Insch ON BIS.Id = Insch.Id;
UPDATE BIS SET IsSchedule = 0, UpdatedById = @UserId, UpdatedTime = @ModificationTime
FROM BlendedIncomeSchedules BIS
JOIN @IncomeSchedules Insch ON BIS.Id = Insch.Id;
END

GO
