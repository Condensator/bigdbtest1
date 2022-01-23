SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateFullPortionIncomeSchedules]
(
@ContractIds ContractIdTVP READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET(7)
)
AS
SET NOCOUNT ON;
Select LeaseIncomeSchedules.Id into #IncomeScheduleIdsToInactivate
FROM LeaseIncomeSchedules
JOIN Leasefinances ON LeaseIncomeSchedules.LeaseFinanceId = Leasefinances.Id
JOIN @ContractIds contractIds ON Leasefinances.ContractId = contractIds.Id
WHERE LeaseIncomeSchedules.IsLessorOwned = 0 AND IsSchedule=1 AND IncomeType = 'FixedTerm'
UPDATE LeaseIncomeSchedules Set IsSchedule = 0 ,
UpdatedById = @UpdatedById ,
UpdatedTime = @UpdatedTime
FROM LeaseIncomeSchedules
JOIN #IncomeScheduleIdsToInactivate ON LeaseIncomeSchedules.Id = #IncomeScheduleIdsToInactivate.Id
UPDATE AssetIncomeSchedules Set IsActive =0,
UpdatedById = @UpdatedById ,
UpdatedTime = @UpdatedTime
From AssetIncomeSchedules
JOIN #IncomeScheduleIdsToInactivate ON AssetIncomeSchedules.LeaseIncomeScheduleId = #IncomeScheduleIdsToInactivate.Id
DROP TABLE  #IncomeScheduleIdsToInactivate

GO
