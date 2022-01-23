SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLeaseFloatRateIncomesFromNonAccrual] 
(
	@NonAccrualLeaseFloatRateIncomesToUpdate	NonAccrualLeaseFloatRateIncomesToUpdate READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT * INTO #NonAccrualLeaseFloatRateIncomesToUpdate FROM @NonAccrualLeaseFloatRateIncomesToUpdate

	Create Clustered Index IX_NonAccrualLFI On #NonAccrualLeaseFloatRateIncomesToUpdate (Id);

	UPDATE LeaseFloatRateIncomes
		SET 
			IsScheduled = LFI.IsScheduled,
			IsNonAccrual = LFI.IsNonAccrual,
			IsGLPosted = LFI.IsGLPosted,
			UpdatedTime = @UpdatedTime,
			UpdatedById = @UserId
		FROM LeaseFloatRateIncomes
		JOIN #NonAccrualLeaseFloatRateIncomesToUpdate LFI ON LFI.Id = LeaseFloatRateIncomes.Id

	DROP TABLE #NonAccrualLeaseFloatRateIncomesToUpdate

END

GO
