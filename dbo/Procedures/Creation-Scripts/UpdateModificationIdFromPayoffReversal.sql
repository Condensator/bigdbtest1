SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateModificationIdFromPayoffReversal]
(
@ContractId BIGINT,
@PayoffId BIGINT ,
@PayoffreversalId BIGINT ,
@LeaseFinanceId BIGINT ,
@PayoffLeaseFinanceId BIGINT ,
@LeaseModificationType NVARCHAR(25) ,
--@AssetIds NVARCHAR(MAX),
@EffectiveDate DateTime,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET,
@SourceModule NVARCHAR(MAX)
)
AS
SET NOCOUNT ON
SELECT AssetId FROM LeaseAssets WHERE LeaseFinanceId = @LeaseFinanceId AND IsActive = 1
IF @PayoffreversalId > 0 AND @LeaseFinanceId > 0
BEGIN
/*Updating the OperatingNBV in IncomeSchedules*/
SELECT
IncomeDate ,
AssetId,
sum(BeginBookValue_Amount) AS BeginBookValue_Amount,
sum(EndBookValue_Amount) AS EndBookValue_Amount,
sum(Value_Amount) AS Value_Amount
INTO #AssetValueHistoriesTemp
FROM  dbo.AssetValueHistories
WHERE
SourceModuleId IN (SELECT Id FROM LeaseFinances WHERE ContractId = @ContractId )
AND SourceModule = @SourceModule
AND IsSchedule = 1
AND IsAccounted = 1
AND IsLessorOwned = 1
AND IncomeDate > @EffectiveDate
GROUP BY IncomeDate , AssetId
UPDATE dbo.AssetIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = AVH.BeginBookValue_Amount,
OperatingEndNetBookValue_Amount = AVH.EndBookValue_Amount,
Depreciation_Amount = AVH.Value_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM  dbo.AssetIncomeSchedules AIS
INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
INNER JOIN #AssetValueHistoriesTemp AVH ON LISE.IncomeDate = AVH.IncomeDate
WHERE LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND AVH.AssetId = AIS.AssetId
AND LISE.AdjustmentEntry = 0
DROP TABLE #AssetValueHistoriesTemp
UPDATE dbo.LeaseIncomeSchedules
SET
OperatingBeginNetBookValue_Amount = LIS.OperatingBeginNetBookValue_Amount,
OperatingEndNetBookValue_Amount = LIS.OperatingEndNetBookValue_Amount,
Depreciation_Amount = LIS.Depreciation_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM (
SELECT
AIS.LeaseIncomeScheduleId,
SUM(AIS.OperatingBeginNetBookValue_Amount) [OperatingBeginNetBookValue_Amount],
SUM(AIS.OperatingEndNetBookValue_Amount) [OperatingEndNetBookValue_Amount] ,
SUM(AIS.Depreciation_Amount) [Depreciation_Amount]
FROM dbo.AssetIncomeSchedules AIS
INNER JOIN dbo.LeaseIncomeSchedules LISE ON AIS.LeaseIncomeScheduleId = LISE.Id
WHERE LISE.LeaseFinanceId = @LeaseFinanceId
AND AIS.IsActive = 1
AND LISE.AdjustmentEntry = 0
GROUP BY AIS.LeaseIncomeScheduleId
) AS LIS
WHERE LeaseIncomeSchedules.Id = LIS.LeaseIncomeScheduleId
AND LeaseIncomeSchedules.AdjustmentEntry = 0;

UPDATE LeaseFloatRateIncomes SET ModificationId = @PayoffreversalId, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime 
FROM LeaseFloatRateIncomes
WHERE LeaseFinanceId = @LeaseFinanceId and IncomeDate >= @EffectiveDate and (IsAccounting = 1 or IsScheduled = 1) and ModificationType = @LeaseModificationType and ModificationId = 0;

UPDATE LeaseIncomeSchedules SET LeaseModificationId = @PayoffreversalId, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
FROM LeaseIncomeSchedules
WHERE LeaseFinanceId = @LeaseFinanceId and IncomeDate >= @EffectiveDate and (IsAccounting = 1 or IsSchedule = 1) and LeaseModificationType = @LeaseModificationType and LeaseModificationId = 0;

UPDATE BlendedIncomeSchedules SET ModificationId = @PayoffreversalId, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
FROM BlendedIncomeSchedules
WHERE LeaseFinanceId = @LeaseFinanceId and IncomeDate >= @EffectiveDate and (IsAccounting = 1 or IsSchedule = 1) and ModificationType = @LeaseModificationType and ModificationId = 0;

END
IF @PayoffLeaseFinanceId > 0
BEGIN
UPDATE LeaseFloatRateIncomes SET IsScheduled = 0, IsAccounting = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
WHERE Id IN (
SELECT Id FROM LeaseFloatRateIncomes
WHERE LeaseFloatRateIncomes.LeaseFinanceId = @PayoffLeaseFinanceId and LeaseFloatRateIncomes.IncomeDate > @EffectiveDate)
END
--DECLARE @NonAccrualDate DATE ;
--SELECT @NonAccrualDate = NonAccrualDate FROM NonAccrualContracts WHERE ContractId = @ContractId AND IsActive = 1 ;
--IF @NonAccrualDate IS NOT NULL
--BEGIN
--UPDATE LeaseIncomeSchedules SET IsSchedule = 0, IsAccounting = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
--WHERE LeaseFinanceId = @PayoffLeaseFinanceId
--AND IncomeDate > @NonAccrualDate AND IncomeDate <= @EffectiveDate
--AND LeaseModificationType ='Payoff' AND LeaseModificationID = @PayoffId
--UPDATE AssetIncomeSchedules SET IsActive = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
--FROM AssetIncomeSchedules AIS
--JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
--WHERE LIS.LeaseFinanceId = @PayoffLeaseFinanceId
--AND LIS.IncomeDate > @NonAccrualDate AND LIS.IncomeDate <= @EffectiveDate
--AND LIS.LeaseModificationType ='Payoff' AND LIS.LeaseModificationID = @PayoffId
--UPDATE LeaseFloatRateIncomes SET IsScheduled = 0, IsAccounting = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
--WHERE LeaseFinanceId = @PayoffLeaseFinanceId
--AND IncomeDate > @NonAccrualDate AND IncomeDate <= @EffectiveDate
--AND ModificationType ='Payoff' AND ModificationID = @PayoffId
--UPDATE AssetFloatRateIncomes SET IsActive = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
--FROM AssetFloatRateIncomes AIS
--JOIN LeaseFloatRateIncomes LIS ON AIS.LeaseFloatRateIncomeId = LIS.Id
--WHERE LIS.LeaseFinanceId = @PayoffLeaseFinanceId
--AND LIS.IncomeDate > @NonAccrualDate AND LIS.IncomeDate <= @EffectiveDate
--AND LIS.ModificationType ='Payoff' AND LIS.ModificationID = @PayoffId
--UPDATE BlendedIncomeSchedules SET IsSchedule = 0, IsAccounting = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
--WHERE LeaseFinanceId = @PayoffLeaseFinanceId
--AND IncomeDate > @NonAccrualDate AND IncomeDate <= @EffectiveDate
--AND ModificationType ='Payoff' AND ModificationID = @PayoffId
--END

GO
