SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateLeaseIncomeSchedules] 
(
	@UpdateLeaseIncomeSchedules LeaseIncomeScheduleDetails READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	UPDATE LeaseIncomeSchedules
	SET 
		IsAccounting = UPLIS.IsAccounting,
		IsNonAccrual = UPLIS.IsNonAccrual,
		IsGLPosted = UPLIS.IsGLPosted,
		IsSchedule = UPLIS.IsSchedule,
		PostDate = UPLIS.PostDate,
		UpdatedTime = @UpdatedTime,
		UpdatedById = @UserId
	FROM LeaseIncomeSchedules
	JOIN @UpdateLeaseIncomeSchedules UPLIS ON UPLIS.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id

	UPDATE AssetIncomeSchedules
	SET
		IsActive = 0,
		UpdatedTime = @UpdatedTime,
		UpdatedById = @UserId
	FROM AssetIncomeSchedules
	JOIN @UpdateLeaseIncomeSchedules UPLIS ON UPLIS.LeaseIncomeScheduleId = AssetIncomeSchedules.LeaseIncomeScheduleId

END

GO
