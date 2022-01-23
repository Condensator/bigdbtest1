SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VP_GetAssetFeatures]
(
@AssetId bigint
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
AF.Alias AS Alias,
AF.Quantity AS Quantity,
M.Name AS Manufacturer,
AF.Description AS Description,
AC.Name AS Category,
P.Name AS Product,
AT.Name AS AssetType,
AF.IsActive AS IsActive
FROM AssetFeatures AF
JOIN AssetTypes AT ON AF.TypeId = AT.Id
JOIN Products P ON AT.ProductId = P.Id
JOIN AssetCategories AC ON AC.Id = P.AssetCategoryId
LEFT JOIN Manufacturers M on AF.ManufacturerId = M.Id
WHERE AF.AssetId = @AssetId
END

GO
