SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateBlendedIncomeSchedulesFromNonAccrual] 
(
	@NonAccrualBlendedIncomesToUpdate			NonAccrualBlendedIncomesToUpdate		READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT * INTO #NonAccrualBlendedIncomesToUpdate FROM @NonAccrualBlendedIncomesToUpdate

	Create Clustered Index IX_NonAccrualBIS On #NonAccrualBlendedIncomesToUpdate (Id);

	UPDATE BlendedIncomeSchedules
		SET 		
			IsSchedule = BIS.IsSchedule,
			IsNonAccrual = BIS.IsNonAccrual,
			PostDate = BIS.PostDate,
			ReversalPostDate = BIS.ReversalPostDate,
			UpdatedTime = @UpdatedTime,
			UpdatedById = @UserId
		FROM BlendedIncomeSchedules
		JOIN #NonAccrualBlendedIncomesToUpdate BIS ON BIS.Id = BlendedIncomeSchedules.Id

	DROP TABLE #NonAccrualBlendedIncomesToUpdate
END

GO
