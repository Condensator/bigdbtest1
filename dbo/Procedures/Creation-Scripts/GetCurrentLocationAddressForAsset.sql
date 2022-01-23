SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCurrentLocationAddressForAsset](@AssetId BIGINT,
@Address NVARCHAR(MAX) OUT)
AS
BEGIN
SET @Address = dbo.GetAssetLocationAsCSV(@AssetId);
END;

GO
