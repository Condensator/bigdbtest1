SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ClearBlendedItemBalanceChargeOff]
(
@ContractType NVARCHAR(20),
@ChargeOffDate DATETIME,
@FinanceId BIGINT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@OpenPeriodStartDate DATETIME
)
AS
BEGIN
SET NOCOUNT ON;
IF @ContractType = 'Lease'
BEGIN
/* Charge off date is Charge odd date (-1) day if chargeodd date > commence date */
IF @ChargeOffDate >= @OpenPeriodStartDate /* Charge Off in Open Period */
BEGIN
UPDATE BIS SET BIS.IsSchedule = 0, BIS.IsAccounting = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LeaseFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate > @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IncomeBalance_Amount = 0.0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LeaseFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate = @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate AND BI.BookRecognitionMode = 'Amortize'
AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IncomeBalance_Amount = BI.Amount_Amount,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LeaseFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate = @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate AND BI.BookRecognitionMode = 'Accrete'
AND BIS.AdjustmentEntry = 0
END
ELSE   /* Charge Off in closed Period */
BEGIN
UPDATE BIS SET BIS.IsSchedule = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LeaseFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate > @ChargeOffDate AND  BIS.IncomeDate < @OpenPeriodStartDate  AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IsSchedule = 0,BIS.IsAccounting = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LeaseBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LeaseFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate >= @OpenPeriodStartDate  AND BIS.AdjustmentEntry = 0
END
END
ELSE
BEGIN
IF @ChargeOffDate >= @OpenPeriodStartDate /* Charge Off in Open Period */
BEGIN
UPDATE BIS SET BIS.IsSchedule = 0, BIS.IsAccounting = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LoanBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LoanFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate > @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IncomeBalance_Amount = 0.0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LoanBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LoanFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate = @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BI.BookRecognitionMode = 'Amortize'
AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IncomeBalance_Amount = BI.Amount_Amount,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LoanBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LoanFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate = @ChargeOffDate AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BI.BookRecognitionMode = 'Accrete' AND BIS.AdjustmentEntry = 0
END
ELSE /* Charge Off in closed Period */
BEGIN
UPDATE BIS SET BIS.IsSchedule = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LoanBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LoanFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate > @ChargeOffDate AND  BIS.IncomeDate < @OpenPeriodStartDate
AND BIS.AdjustmentEntry = 0
UPDATE BIS SET BIS.IsSchedule = 0,BIS.IsAccounting = 0,BIS.UpdatedTime =@UpdatedTime, BIS.UpdatedById =@UpdatedById
FROM BlendedIncomeSchedules BIS
JOIN BlendedItems BI ON BIS.BlendedItemId = BI.Id
JOIN LoanBlendedItems LBI ON BI.Id = LBI.BlendedItemId
WHERE LBI.LoanFinanceId = @FinanceId AND BI.IsActive = 1 AND BI.IsFAS91 = 1
AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BIS.AdjustmentEntry = 0
END
END
END

GO
