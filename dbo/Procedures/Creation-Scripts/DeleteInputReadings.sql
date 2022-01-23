SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteInputReadings]
(
@InstanceId UNIQUEIDENTIFIER
)
AS
BEGIN
SET NOCOUNT ON
DELETE FROM EnmasseMeterReadingLogs WHERE EnmasseMeterReadingInstanceId in (
SELECT Id
FROM EnmasseMeterReadingInstances WHERE InstanceId = @InstanceId
)
DELETE FROM EnmasseMeterReadingInstances WHERE InstanceId = @InstanceId
DELETE FROM EnmasseMeterReadingInputs WHERE InstanceId = @InstanceId
SET NOCOUNT OFF
END

GO
