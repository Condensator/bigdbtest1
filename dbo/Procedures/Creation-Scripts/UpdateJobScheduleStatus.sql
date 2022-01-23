SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateJobScheduleStatus]
(
	@JobServiceIdCSV NVARCHAR(MAX),
	@Recurring NVARCHAR(15),
	@OneTime NVARCHAR(15),
	@ChangedStatus NVARCHAR(15),
	@SubmittedStatus NVARCHAR(15),
	@Approved NVARCHAR(15),
	@UserId BIGINT,
	@CurrentTime DATETIMEOFFSET
)
AS

SET NOCOUNT ON;

CREATE TABLE #UpdatedJobIds(
	Id BIGINT NOT NULL
);

SELECT Id
INTO #JobServiceIds
FROM ConvertCSVToBigIntTable(@jobServiceIdCSV, ',')

begin tran

INSERT INTO #UpdatedJobIds
SELECT 
j.Id
from Jobs j 
join #JobServiceIds #js on j.JobServiceId = #js.Id
where  IsActive = 1
  AND ApprovalStatus = @Approved 
  AND ScheduledStatus = @SubmittedStatus	
  AND (
			(ScheduleType = @Recurring AND (ExpiryDate IS NULL OR ExpiryDate >= @CurrentTime)) 
		 OR (ScheduleType = @OneTime AND ScheduleDate >= @CurrentTime)
	  )


update J set 
	ScheduledStatus = @ChangedStatus
	, UpdatedById = @UserId
	, UpdatedTime= @CurrentTime	
	, JobServiceId = null 
from Jobs j 
INNER JOIN #UpdatedJobIds #UJ ON J.Id = #UJ.Id
	
	SELECT * FROM #UpdatedJobIds

	DROP TABLE #UpdatedJobIds

commit


GO
