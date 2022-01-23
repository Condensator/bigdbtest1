SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateNonAccrualQuoteStatus]
(
	@CurrentUserId					BIGINT,
	@CurrentTime					DATETIMEOFFSET,
	@ApprovedStatus					NVARCHAR(50),
	@PartiallyApprovedStatus		NVARCHAR(50),
	@FaultedStatus					NVARCHAR(50),
	@NonAccrualId					BIGINT,
	@JobId							BIGINT
)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @TotalCount BIGINT = 0
	DECLARE @SuccessCount BIGINT = 0
	DECLARE @StatusToUpdate NVARCHAR(50) = @FaultedStatus

	SELECT 
	@TotalCount = COUNT(1)
	FROM NonAccrualContracts
	WHERE NonAccrualId = @NonAccrualId AND IsActive = 1

	SELECT 
	@SuccessCount = COUNT(1)
	FROM NonAccrualContracts
	WHERE NonAccrualId = @NonAccrualId AND IsNonAccrualApproved = 1 AND IsActive = 1

	IF @TotalCount = @SuccessCount
	BEGIN
		SET @StatusToUpdate = @ApprovedStatus
	END
	ELSE IF @SuccessCount > 0
	BEGIN
		SET @StatusToUpdate = @PartiallyApprovedStatus
	END

	UPDATE NonAccruals SET [Status] = @StatusToUpdate, UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime, JobId = @JobId
	WHERE Id = @NonAccrualId
END

GO
