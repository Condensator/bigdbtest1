SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FetchLocationInfoForLocationTaxAreaValidate]
(
@LocationId BIGINT
)
AS
BEGIN


DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

SELECT Distinct TOP 1000
Location.Id AS LocationId,
Location.Code AS LocationCode,
CASE WHEN Location.Latitude IS NOT NULL AND Location.Longitude IS NOT NULL THEN State.LongName ELSE Location.State END AS MainDivision,
Location.Country AS CountryName,
Location.PostalCode AS PostalCode,
Location.Division SubDivision,
Location.AddressLine1 AS AddressLine1,
Location.City AS City,
ISNULL(Location.TaxAreaVerifiedTillDate,GETDATE()) AS AsOfDate,
ISNULL(Location.TaxAreaId,0) AS TaxAreaId,
Location.Latitude AS Latitude,
Location.Longitude AS Longitude
FROM stgLocation Location
INNER JOIN Countries Country ON Country.ShortName = Location.Country
INNER JOIN States State ON state.ShortName = Location.state AND State.IsActive = 1
WHERE Location.IsMigrated = 0 AND Location.IsLocationValidated = 0 AND Country.TaxSourceType = @TaxSourceTypeVertex
AND Location.Id > @LocationId
ORDER BY Location.Id
END

GO
