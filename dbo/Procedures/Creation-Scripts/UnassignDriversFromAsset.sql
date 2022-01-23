SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UnassignDriversFromAsset]
(
@AssetIds NVARCHAR(MAX),
@UnassignDate DATETIME,
@UpdatedById Bigint,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE
DriversAssignedToAssets
SET
Assign = 0, UnassignedDate = @UnassignDate, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
WHERE AssetId IN (SELECT Id FROM ConvertCSVToBigIntTable(@AssetIds,','))
AND Assign = 1
END

GO
