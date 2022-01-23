SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateLocations]
(@UserId                  BIGINT,
@ModuleIterationStatusId BIGINT,
@CreatedTime             DATETIMEOFFSET,
@ProcessedRecords        BIGINT OUTPUT,
@FailedRecords           BIGINT OUTPUT
)
AS
BEGIN

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
DECLARE @TaxSourceTypeNonVertex NVARCHAR(10);

SET @TaxSourceTypeVertex = 'Vertex';
SET @TaxSourceTypeNonVertex = 'NonVertex';

CREATE TABLE #ErrorLogs
(Id                  BIGINT NOT NULL IDENTITY PRIMARY KEY,
StagingRootEntityId BIGINT,
Result              NVARCHAR(10),
Message             NVARCHAR(MAX)
);
CREATE TABLE #FailedProcessingLogs
([Id]         BIGINT NOT NULL,
[LocationId] BIGINT NOT NULL
);
CREATE TABLE #CreatedProcessingLogs([Id] BIGINT NOT NULL);
SET @ProcessedRecords =
(
SELECT ISNULL(COUNT(Id), 0)
FROM stgLocation
WHERE IsMigrated = 0
);
CREATE TABLE #JurisdictionIds
(JurisdictionId       BIGINT,
JurisdictionDetailId BIGINT,
LocationId           BIGINT
);
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Selected State must be Active for Location : ' + location.Code) AS Message
FROM stgLocation location
INNER JOIN States s ON location.[State] = s.ShortName
AND s.IsActive = 0
WHERE location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Selected State must be valid for Location : ' + location.Code) AS Message
FROM stgLocation location
LEFT JOIN States s ON location.[State] = s.ShortName
AND s.IsActive = 1
WHERE s.Id IS NULL
AND location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Selected Country must be valid for Location : ' + location.Code) AS Message
FROM stgLocation location
LEFT JOIN Countries c ON location.Country = c.ShortName
AND c.IsActive = 1
WHERE c.Id IS NULL
AND location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Selected Country must be Active for Location : ' + location.Code) AS Message
FROM stgLocation location
INNER JOIN Countries c ON location.Country = c.ShortName
WHERE c.IsActive = 0
AND location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Postal Code is required for Location : ' + location.Code) AS Message
FROM stgLocation location
INNER JOIN Countries Country ON Country.ShortName = location.Country
WHERE Country.IsPostalCodeMandatory = 1
AND location.PostalCode IS NULL AND (location.Latitude IS NULL AND location.Longitude IS NULL)
AND location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Invalid Portfolio Name for Location : ' + location.Code) AS Message
FROM stgLocation location
LEFT JOIN Portfolios ON Portfolios.Name = location.PortfolioName
WHERE Portfolios.Id IS NULL
AND location.IsMigrated = 0;
INSERT INTO #JurisdictionIds
SELECT DISTINCT
NULL
, NULL
, location.Id
FROM stgLocation location
WHERE ismigrated = 0;

INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('Coordinates can be used only for Vertex Supported Location Creation [ Location Code ]: [' + location.Code + ' ]') AS Message
FROM stgLocation location
INNER JOIN Countries c ON location.Country = c.ShortName
AND c.isActive = 1
WHERE c.TaxSourceType = @TaxSourceTypeNonVertex
AND (location.Latitude IS NOT  NULL OR location.Longitude IS NOT NULL)
AND location.IsMigrated = 0;

INSERT INTO #ErrorLogs
SELECT
 L.Id
	,'Error'
	,('Latitude is required for given Longitude[ Location Code ]: [' + L.Code + ' ]') AS Message
FROM 
stgLocation L
WHERE l.Latitude IS NULL AND l.Longitude IS NOT NULL AND l.IsMigrated = 0;
		
INSERT INTO #ErrorLogs
SELECT
 L.Id
	,'Error'
	,('Longitude is required for given Latitude [ Location Code ]: [' + L.Code + ' ]') AS Message
FROM 
stgLocation L
WHERE l.Latitude IS NOT NULL AND l.Longitude IS  NULL AND l.IsMigrated = 0;


INSERT INTO #ErrorLogs
SELECT 
 L.Id
	,'Error'
	,('AddressLine1 required for Location [Location code]: ['+L.Code+']') AS Message
FROM stgLocation L
WHERE l.Longitude IS  NULL AND l.Longitude IS  NULL AND l.AddressLine1 IS NULL AND l.IsMigrated = 0;

--NonVertex
UPDATE #JurisdictionIds
SET
JurisdictionId = J.Id
, JurisdictionDetailId = CASE
WHEN JD.PostalCode = location.PostalCode
AND location.IncludedPostalCodeInLocationLookup = 1
THEN JD.ID
ELSE NULL
END
FROM #JurisdictionIds
JOIN stgLocation location ON #JurisdictionIds.LocationId = location.Id
JOIN States S ON location.State = S.ShortName
JOIN Countries C ON S.CountryId = C.Id
AND location.Country = C.ShortName
JOIN Cities city ON location.City = city.Name
LEFT JOIN Counties division ON location.Division = division.Name
LEFT JOIN Jurisdictions J ON J.CityId = city.Id
AND J.CountyId = division.Id
AND J.stateId = S.Id
AND J.CountryId = C.Id
AND J.IsActive = 1
LEFT JOIN JurisdictionDetails JD ON JD.JurisdictionId = J.Id
AND JD.PostalCode = location.PostalCode
AND JD.IsActive = 1
WHERE C.TaxSourceType = @TaxSourceTypeNonVertex;



WITH CTE_JurisdictionDetail
AS (SELECT J.ID       JusridictionId
, MAX(JD.ID) JurisdictionDetailId
FROM Jurisdictions J
LEFT JOIN JurisdictionDetails JD ON JD.JurisdictionId = J.Id
AND JD.IsActive = 1
AND J.IsActive = 1
JOIN #JurisdictionIds #J ON #J.JurisdictionId = J.ID
WHERE #J.JurisdictionDetailId IS NULL
GROUP BY J.ID)
UPDATE #JurisdictionIds
SET
JurisdictionDetailId = cte.JurisdictionDetailId
FROM #JurisdictionIds J
JOIN CTE_JurisdictionDetail cte ON J.JurisdictionId = cte.JusridictionId
WHERE J.JurisdictionDetailId IS NULL;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('The State does not belong to the Country for Location Code :'+location.Code) AS Message
FROM stgLocation location
INNER JOIN Countries c ON location.Country = c.ShortName
LEFT JOIN States s ON c.Id = s.CountryId and location.State = s.ShortName
where s.Id is null
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('No Jurisdiction found with combination [ Division, City, State, Country ] : [ ' + ISNULL(location.Division, 'NULL') + ', ' + ISNULL(location.city, 'NULL') + ', ' + ISNULL(location.State, 'NULL') + ', ' + ISNULL(location.Country, 'NULL') + ' ] for Location : ' + location.Code) AS Message
FROM stgLocation location
INNER JOIN Countries c ON location.Country = c.ShortName
AND c.isActive = 1
LEFT JOIN #JurisdictionIds J ON J.LocationId = location.Id
WHERE J.JurisdictionId IS NULL
AND c.TaxSourceType = @TaxSourceTypeNonVertex
AND location.IsMigrated = 0;
INSERT INTO #ErrorLogs
SELECT location.Id
, 'Error'
, ('TaxAreaId is required for Vertex supported Location  [ Location Code ]: [' + location.Code + ' ]') AS Message
FROM stgLocation location
INNER JOIN Countries c ON location.Country = c.ShortName
AND c.isActive = 1
WHERE c.TaxSourceType = @TaxSourceTypeVertex
AND (location.TaxAreaId = 0
OR location.TaxAreaId IS NULL
OR location.TaxAreaId = '')
AND location.IsMigrated = 0;
SET @FailedRecords =
(
SELECT ISNULL(COUNT(DISTINCT StagingRootEntityId), 0)
FROM #ErrorLogs
);
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT Id
FROM stgLocation
WHERE IsMigrated = 0
AND Id NOT IN
(
SELECT StagingRootEntityId
FROM #ErrorLogs
)
) AS ProcessedLocations
ON(ProcessingLog.StagingRootEntityId = ProcessedLocations.Id
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ProcessedLocations.Id
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
INTO #CreatedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT 'Successful'
, 'Information'
, @UserId
, @CreatedTime
, Id
FROM #CreatedProcessingLogs;
MERGE stgProcessingLog AS ProcessingLog
USING
(
SELECT DISTINCT
StagingRootEntityId
FROM #ErrorLogs
) AS ErrorLocations
ON(ProcessingLog.StagingRootEntityId = ErrorLocations.StagingRootEntityId
AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED
THEN UPDATE SET
UpdatedTime = @CreatedTime
, UpdatedById = @UserId
WHEN NOT MATCHED
THEN
INSERT(StagingRootEntityId
, CreatedById
, CreatedTime
, ModuleIterationStatusId)
VALUES
(ErrorLocations.StagingRootEntityId
, @UserId
, @CreatedTime
, @ModuleIterationStatusId
)
OUTPUT Inserted.Id
, ErrorLocations.StagingRootEntityId
INTO #FailedProcessingLogs;
INSERT INTO stgProcessingLogDetail
(Message
, Type
, CreatedById
, CreatedTime
, ProcessingLogId
)
SELECT #ErrorLogs.Message
, 'Error'
, @UserId
, @CreatedTime
, #FailedProcessingLogs.Id
FROM #ErrorLogs
JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.LocationId;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;
DROP TABLE #CreatedProcessingLogs;
DROP TABLE #JurisdictionIds;
END;

GO
