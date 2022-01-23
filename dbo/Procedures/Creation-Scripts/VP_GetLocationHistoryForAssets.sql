SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VP_GetLocationHistoryForAssets]
(
@AssetId bigint
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
AL.EffectiveFromDate AS EffectiveDate,
L.Code AS  LocationCode,
L.Name AS LocationName,
(CASE WHEN L.AddressLine2 != 'NULL' THEN L.AddressLine1 +' '+ L.AddressLine2 ELSE L.AddressLine1 END) AS Address,
L.City AS City,
S.LongName AS County,
S.LongName AS State,
C.LongName AS Country,
L.PostalCode AS Zip,
AL.IsCurrent AS CurrentLocation
FROM AssetLocations AL
JOIN Assets A ON AL.AssetId = A.Id
JOIN Locations L ON AL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON S.CountryId = C.Id
WHERE A.Id = @AssetId
END

GO
