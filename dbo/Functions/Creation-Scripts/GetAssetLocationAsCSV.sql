SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAssetLocationAsCSV]
(@AssetId BIGINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @Address NVARCHAR(MAX)= '';
SELECT @Address = ISNULL([Extent2].AddressLine1+' ,', '')+ISNULL([Extent2].AddressLine2+' ,', '')+ISNULL([Extent2].City+' ,', '')+ISNULL([Extent3].ShortName+' ,', '')+ISNULL([Extent2].PostalCode, '')
FROM [dbo].[AssetLocations] AS [Extent1]
INNER JOIN [dbo].[Locations] AS [Extent2] ON [Extent1].[LocationId] = [Extent2].[Id]
INNER JOIN [dbo].[States] AS [Extent3] ON [Extent2].[StateId] = [Extent3].[Id]
INNER JOIN [dbo].[Countries] AS [Extent4] ON [Extent3].[CountryId] = [Extent4].[Id]
WHERE([Extent1].[IsCurrent] = 1)
AND ([Extent1].[IsActive] = 1)
AND ([Extent2].[IsActive] = 1)
AND ([Extent3].[IsActive] = 1)
AND ([Extent1].[AssetId] = @AssetId)
AND ([Extent4].[IsActive] = 1);
RETURN @Address;
END;

GO
