SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateJobServiceStopTime]
(
	@JobServiceId BIGINT
	,@StopTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

	DECLARE @LatestJobServiceDetailId BIGINT

	SET @LatestJobServiceDetailId = 
	( 
		SELECT
		TOP 1 
		Id
		FROM JobServiceDetails
		WHERE   JobServiceId = @JobServiceId 
			AND StopTime IS NULL
		ORDER BY Id DESC
	);

	UPDATE JobServiceDetails
	SET
		StopTime = @StopTime
		,UpdatedById = CreatedById
		,UpdatedTime = @StopTime
	WHERE Id =  @LatestJobServiceDetailId

END

GO
