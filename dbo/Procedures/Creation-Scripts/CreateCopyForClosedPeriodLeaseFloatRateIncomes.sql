SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateCopyForClosedPeriodLeaseFloatRateIncomes]
(
@FloatRateIncomes FloatRateIncomesToClone READONLY,
@ModificationType NVARCHAR(50),
@ModificationId BIGINT,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET,
@IsNonAccrual BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @OldIncomeId BIGINT;
DECLARE @NewIncomeId BIGINT;
DECLARE IncomeSchedulesCursor CURSOR LOCAL FOR (SELECT Id FROM @FloatRateIncomes);
OPEN IncomeSchedulesCursor;
FETCH NEXT FROM IncomeSchedulesCursor INTO @OldIncomeId;
WHILE @@FETCH_STATUS = 0
BEGIN
INSERT INTO LeaseFloatRateIncomes
(IncomeDate
,CustomerIncomeAmount_Amount
,CustomerIncomeAmount_Currency
,CustomerIncomeAccruedAmount_Amount
,CustomerIncomeAccruedAmount_Currency
,CustomerReceivableAmount_Amount
,CustomerReceivableAmount_Currency
,IsGLPosted
,IsAccounting
,IsScheduled
,IsNonAccrual
,ModificationType
,ModificationId
,AdjustmentEntry
,IsLessorOwned
,InterestRate
,CreatedById
,CreatedTime
,FloatRateIndexDetailId
,LeaseFinanceId)
SELECT
IncomeDate
,CustomerIncomeAmount_Amount
,CustomerIncomeAmount_Currency
,CustomerIncomeAccruedAmount_Amount
,CustomerIncomeAccruedAmount_Currency
,CustomerReceivableAmount_Amount
,CustomerReceivableAmount_Currency
,0
,0
,1
,@IsNonAccrual
,@ModificationType
,@ModificationId
,0
,IsLessorOwned
,InterestRate
,@UserId
,@ModificationTime
,FloatRateIndexDetailId
,LeaseFinanceId
FROM LeaseFloatRateIncomes WHERE Id = @OldIncomeId;
SET @NewIncomeId = SCOPE_IDENTITY();
INSERT INTO AssetFloatRateIncomes
(CustomerIncomeAmount_Amount
,CustomerIncomeAmount_Currency
,CustomerIncomeAccruedAmount_Amount
,CustomerIncomeAccruedAmount_Currency
,CustomerReceivableAmount_Amount
,CustomerReceivableAmount_Currency
,IsActive
,CreatedById
,CreatedTime
,AssetId
,LeaseFloatRateIncomeId)
SELECT
CustomerIncomeAmount_Amount
,CustomerIncomeAmount_Currency
,CustomerIncomeAccruedAmount_Amount
,CustomerIncomeAccruedAmount_Currency
,CustomerReceivableAmount_Amount
,CustomerReceivableAmount_Currency
,1
,@UserId
,@ModificationTime
,AssetId
,@NewIncomeId
FROM AssetFloatRateIncomes
WHERE LeaseFloatRateIncomeId = @OldIncomeId AND AssetFloatRateIncomes.IsActive=1 ;
FETCH NEXT FROM IncomeSchedulesCursor INTO @OldIncomeId;
END
CLOSE IncomeSchedulesCursor;
DEALLOCATE IncomeSchedulesCursor;
UPDATE AFI SET IsActive = 0, UpdatedById = @UserId, UpdatedTime = @ModificationTime
FROM AssetFloatRateIncomes AFI
JOIN @FloatRateIncomes Inc ON AFI.LeaseFloatRateIncomeId = Inc.Id;
UPDATE LFI SET IsScheduled = 0, UpdatedById = @UserId, UpdatedTime = @ModificationTime
FROM LeaseFloatRateIncomes LFI
JOIN @FloatRateIncomes Inc ON LFI.Id = Inc.Id;
END

GO
