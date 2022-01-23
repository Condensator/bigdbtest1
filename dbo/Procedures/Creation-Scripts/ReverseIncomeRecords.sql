SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReverseIncomeRecords]
(
@OpenPeriodStartDate DATETIME,
@ContractId BIGINT,
@IsLease BIT,
@ChargeOffDate DATETIME,
@UpdatedById  BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LeaseIncomeSchedules SET IsAccounting = 0, UpdatedTime = @UpdatedTime, UpdatedById = @UpdatedById FROM LeaseIncomeSchedules LIS
JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND LIS.IncomeDate >= @ChargeOffDate
AND LIS.IncomeDate >= @OpenPeriodStartDate
AND @IsLease = 1
AND LIS.IsSchedule = 1
AND LIS.IsAccounting = 1
UPDATE LoanIncomeSchedules SET IsAccounting = 0, UpdatedTime = @UpdatedTime, UpdatedById = @UpdatedById FROM LoanIncomeSchedules LIS
JOIN LoanFinances LF ON LIS.LoanFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND LIS.IncomeDate >= @ChargeOffDate
AND LIS.IncomeDate >= @OpenPeriodStartDate
AND @IsLease = 0
AND LIS.IsSchedule = 1
AND LIS.IsAccounting = 1
UPDATE LeaseFloatRateIncomes SET IsAccounting = 0, UpdatedTime = @UpdatedTime, UpdatedById = @UpdatedById FROM LeaseFloatRateIncomes LFI
JOIN LeaseFinances LF ON LFI.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND LFI.IncomeDate >= @ChargeOffDate
AND LFI.IncomeDate >= @OpenPeriodStartDate
AND @IsLease = 1
AND LFI.IsScheduled = 1
AND LFI.IsAccounting = 1
IF(@IsLease = 1)
BEGIN
UPDATE BlendedIncomeSchedules SET IsAccounting = 0, UpdatedTime = @UpdatedTime, UpdatedById = @UpdatedById FROM BlendedIncomeSchedules BIS
JOIN LeaseBlendedItems LBI ON BIS.BlendedItemId = LBI.BlendedItemId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id
JOIN LeaseFinances LF ON LBI.LeaseFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND BIS.IncomeDate >= @ChargeOffDate
AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BI.BookRecognitionMode	!= 'Accrete' AND BI.BookRecognitionMode	!= 'Capitalize'
AND BIS.IsSchedule = 1
AND BIS.IsAccounting = 1
AND BI.IsActive = 1
AND BI.IsFAS91 = 1
AND BI.Id != BI.RelatedBlendedItemId
END
ELSE
BEGIN
UPDATE BlendedIncomeSchedules SET IsAccounting = 0, UpdatedTime = @UpdatedTime, UpdatedById = @UpdatedById FROM BlendedIncomeSchedules BIS
JOIN LoanBlendedItems LBI ON BIS.BlendedItemId = LBI.BlendedItemId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id
JOIN LoanFinances LF ON LBI.LoanFinanceId = LF.Id
WHERE LF.ContractId = @ContractId
AND BI.BookRecognitionMode	!= 'Accrete' AND BI.BookRecognitionMode	!= 'Capitalize'
AND BIS.IncomeDate >= @ChargeOffDate
AND BIS.IncomeDate >= @OpenPeriodStartDate
AND BIS.IsSchedule = 1
AND BIS.IsAccounting = 1
AND BI.IsActive = 1
AND BI.IsFAS91 = 1
AND BI.Id != BI.RelatedBlendedItemId
END
END

GO
