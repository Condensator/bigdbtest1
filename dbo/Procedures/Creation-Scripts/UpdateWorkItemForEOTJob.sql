SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateWorkItemForEOTJob]
(
@Maturity  [MaturityMonitorType] readonly
)
AS
BEGIN
SET NOCOUNT ON
UPDATE WorkItems
SET OwnerUserId = M.AssignId,
Status = (CASE
WHEN M.AssignId IS NOT NULL THEN 'Assigned'
ELSE 'Unassigned'
END)
FROM WorkItems WI
JOIN @Maturity M ON WI.Id = M.WorkItemId
END

GO
