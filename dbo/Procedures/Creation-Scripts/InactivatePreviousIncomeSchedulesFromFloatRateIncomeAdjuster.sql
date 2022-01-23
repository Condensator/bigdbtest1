SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivatePreviousIncomeSchedulesFromFloatRateIncomeAdjuster]
(
@LeaseFloatRateIncomeIds LeaseFloatRateIncomeDetailsParam READONLY,
@KeepOldIncomeActive Bit,
@OpenPeriodStartDate DATETIME=NULL,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
UPDATE LeaseFloatRateIncomes SET IsScheduled = @KeepOldIncomeActive,UpdatedTime=@UpdatedTime,UpdatedById=@UpdatedById
FROM @LeaseFloatRateIncomeIds LFRID
WHERE LeaseFloatRateIncomes.Id =LFRID.Id


UPDATE LeaseFloatRateIncomes SET IsGLPosted = 0,IsAccounting =0,UpdatedTime=@UpdatedTime,UpdatedById=@UpdatedById
FROM @LeaseFloatRateIncomeIds LFRID
WHERE LeaseFloatRateIncomes.Id =LFRID.Id
AND (@OpenPeriodStartDate IS NULL OR LeaseFloatRateIncomes.IncomeDate>= @OpenPeriodStartDate)


IF @KeepOldIncomeActive =0
BEGIN
UPDATE AssetFloatRateIncomes SET IsActive = 0,UpdatedTime=@UpdatedTime,UpdatedById=@UpdatedById
FROM @LeaseFloatRateIncomeIds LFRID
JOIN LeaseFloatRateIncomes leaseFloatRateIncome ON LFRID.Id = leaseFloatRateIncome.Id
WHERE AssetFloatRateIncomes.LeasefloatRateIncomeId =LFRID.Id AND ( @OpenPeriodStartDate IS NULL OR leaseFloatRateIncome.IncomeDate >= @OpenPeriodStartDate)
END


GO
