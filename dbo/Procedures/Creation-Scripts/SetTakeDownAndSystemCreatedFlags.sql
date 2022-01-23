SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SetTakeDownAndSystemCreatedFlags]
(
@AssetIds NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON
Create table #AssetId
(
Id BIGINT
)
INSERT INTO #AssetId (Id) SELECT Id FROM ConvertCSVToBigIntTable(@AssetIds,',');
UPDATE Assets SET Assets.IsSystemCreated=1 , Assets.IsTakedownAsset =1
FROM Assets INNER JOIN #AssetId ON Assets.Id = #AssetId.Id
DROP TABLE #AssetId
END

GO
