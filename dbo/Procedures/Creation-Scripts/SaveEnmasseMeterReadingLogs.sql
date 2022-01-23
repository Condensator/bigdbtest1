SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SaveEnmasseMeterReadingLogs]
(
@val CPUAssetMeterReadingErrorInfoForBulkProcess READONLY
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE EnmasseMeterReadingInstances
SET IsFaulted =1
FROM EnmasseMeterReadingInstances
JOIN  @val  CPUAssetMeterReadingUploadValidation ON EnmasseMeterReadingInstances.Id = CPUAssetMeterReadingUploadValidation.EnmasseMeterReadingInstanceId
MERGE [dbo].[EnmasseMeterReadingLogs] AS T
USING (SELECT * FROM @val) AS S
ON ( T.Id = S.Id)
WHEN MATCHED THEN
UPDATE SET [Error]=S.[Error]
WHEN NOT MATCHED THEN
INSERT ([EnmasseMeterReadingInstanceId],[CreatedById],[CreatedTime],[Error])
VALUES (S.[EnmasseMeterReadingInstanceId],S.[CreatedById],S.[CreatedTime],S.[Error]);
SET NOCOUNT OFF;
END

GO
