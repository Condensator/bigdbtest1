SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InactivateJobSchedulerKeys]
(
	@JobId bigint,		
	@CurrentTime datetimeoffset	
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @UserId bigint;
SELECT @UserId = SubmittedUserId FROM Jobs WHERE Id=@JobId

UPDATE JobSchedulerKeys 
SET 
IsActive=0,
UpdatedById=@UserId,
UpdatedTime=@CurrentTime
WHERE JobId=@JobId and IsActive=1

END

GO
