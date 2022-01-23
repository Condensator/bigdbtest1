SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MonitorJobService]
(
	@NonPollingJobServiceIdsCSV NVARCHAR(MAX),
	@CurrentJobServiceId BIGINT,
	@RecentActiveTime DATETIMEOFFSET
)
AS

SET NOCOUNT ON;

SELECT Id
INTO #NonPollingJobServiceIds
FROM ConvertCSVToBigIntTable(@NonPollingJobServiceIdsCSV, ',')

begin tran

update JobServices 
set IsRunning = 0,
UpdatedTime=@RecentActiveTime,
UpdatedById=CreatedById
from JobServices js 
join #NonPollingJobServiceIds #npjs on js.Id = #npjs.Id

update JobServices
set IsRunning=1,RecentActiveTime = @RecentActiveTime,UpdatedById=CreatedById,UpdatedTime=@RecentActiveTime
where Id = @CurrentJobServiceId

commit


GO
