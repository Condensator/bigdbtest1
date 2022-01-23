SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ManipulateBlendedIncomeSchedulesForLoan]
(
@IncomeSchedules BlendedIncomeSchedulesForLoan READONLY,
@LoanFinanceId BIGINT,
@ModificationType NVARCHAR(25),
@ModificationId BIGINT,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
MERGE dbo.BlendedIncomeSchedules AS PersistedBlendedIncome
USING @IncomeSchedules AS Income
ON (PersistedBlendedIncome.Id = Income.Id)
WHEN MATCHED THEN
UPDATE SET AdjustmentEntry = Income.AdjustmentEntry
,BlendedItemId = Income.BlendedItemId
,EffectiveInterest_Amount = Income.EffectiveInterest
,EffectiveInterest_Currency = Income.Currency
,EffectiveYield = Income.EffectiveYield
,Income_Amount = Income.Income
,Income_Currency = Income.Currency
,IncomeBalance_Amount = Income.IncomeBalance
,IncomeBalance_Currency = Income.Currency
,IncomeDate = Income.IncomeDate
,IsAccounting = Income.IsAccounting
,IsNonAccrual = Income.IsNonAccrual
,IsSchedule = Income.IsSchedule
,LeaseFinanceId = NULL
,LoanFinanceId = @LoanFinanceId
,ModificationId = @ModificationId
,ModificationType = @ModificationType
,PostDate = Income.PostDate
,ReversalPostDate = NULL
,UpdatedById = @UserId
,UpdatedTime = @Time
WHEN NOT MATCHED THEN
INSERT (AdjustmentEntry
,BlendedItemId
,CreatedById
,CreatedTime
,EffectiveInterest_Amount
,EffectiveInterest_Currency
,EffectiveYield
,Income_Amount
,Income_Currency
,IncomeBalance_Amount
,IncomeBalance_Currency
,IncomeDate
,IsAccounting
,IsNonAccrual
,IsSchedule
,LeaseFinanceId
,LoanFinanceId
,ModificationId
,ModificationType
,PostDate
,ReversalPostDate)
VALUES (Income.AdjustmentEntry
,Income.BlendedItemId
,@UserId
,@Time
,Income.EffectiveInterest
,Income.Currency
,Income.EffectiveYield
,Income.Income
,Income.Currency
,Income.IncomeBalance
,Income.Currency
,Income.IncomeDate
,Income.IsAccounting
,Income.IsNonAccrual
,Income.IsSchedule
,NULL
,@LoanFinanceId
,@ModificationId
,@ModificationType
,Income.PostDate
,NULL)
;
END

GO
