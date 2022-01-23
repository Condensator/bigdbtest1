SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveCPUAssetMeterReadingHeaderOnCommencement]
(
@CPUAssetMeterReadingToSave CPUAssetMeterReadingToSave READONLY,
@CreatedByUserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO [CPUAssetMeterReadingHeaders]
(
[CPUAssetId],
[CreatedById],
[CreatedTime]
)
SELECT
CPUAssetId,
@CreatedByUserId ,
@CreatedTime
FROM
@CPUAssetMeterReadingToSave
SET NOCOUNT OFF;
END

GO
