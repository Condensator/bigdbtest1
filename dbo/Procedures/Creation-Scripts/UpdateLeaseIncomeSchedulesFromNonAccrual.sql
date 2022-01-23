SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLeaseIncomeSchedulesFromNonAccrual] 
(
	@NonAccrualLeaseIncomesToUpdate				NonAccrualLeaseIncomesToUpdate			READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT * INTO #NonAccrualLeaseIncomesToUpdate FROM @NonAccrualLeaseIncomesToUpdate

	Create Clustered Index IX_NonAccrualLIS On #NonAccrualLeaseIncomesToUpdate (Id);	

	UPDATE LeaseIncomeSchedules
		SET 
			IsAccounting = LIS.IsAccounting,
			IsNonAccrual = LIS.IsNonAccrual,
			IsGLPosted = LIS.IsGLPosted,
			IsSchedule = LIS.IsSchedule,
			PostDate = LIS.PostDate,
			UpdatedTime = @UpdatedTime,
			UpdatedById = @UserId
		FROM LeaseIncomeSchedules
		JOIN #NonAccrualLeaseIncomesToUpdate LIS ON LIS.Id = LeaseIncomeSchedules.Id

	DROP TABLE #NonAccrualLeaseIncomesToUpdate

END

GO
