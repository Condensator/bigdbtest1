SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAccessibleActivitiesForCurrentUser] @Userid         BIGINT,
@CurrentSession NVARCHAR(200),
@CustomerId     BIGINT
AS
BEGIN
CREATE TABLE #UserAccessActivityIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #UserNonAccessibleActivityIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #AccessibleActivityIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #NonAccessibleActivityIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #LoggedInUserNotAssociatedDefaultActivityIdsPrimary (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #LoggedInUserNotAssociatedDefaultActivityIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #UnionOfAccessIdandLoggedInUserNotDef (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #ViewableActivityTypeIds (Id BIGINT NOT NULL PRIMARY KEY);
CREATE TABLE #UserAccessibleActivities
(Id                           BIGINT NOT NULL,
Name                         NVARCHAR(250),
Description                  NVARCHAR(500),
Solution                     NVARCHAR(MAX),
FollowUpDate                 DATE,
TargetCompletionDate         DATETIMEOFFSET(7),
IsActive                     BIT,
EntityId                     BIGINT,
EntityNaturalId              NVARCHAR(250),
DefaultPermission            NVARCHAR(1),
CreatedById                  BIGINT,
CreatedTime                  DATETIMEOFFSET(7),
UpdatedById                  BIGINT,
UpdatedTime                  DATETIMEOFFSET(7),
OwnerId                      BIGINT,
ActivityTypeId               BIGINT,
StatusId                     BIGINT,
DocumentListId               BIGINT,
CreatedDate                  DATE,
CompletionDate               DATE,
IsFollowUpRequired           BIT,
InitiatedTransactionEntityId BIGINT,
OwnerGroupId                 BIGINT
);
CREATE TABLE #ActivitiesForCustomerQuery
(Id               BIGINT NOT NULL,
Name             NVARCHAR(2000),
ActivityId       BIGINT NOT NULL,
CreatedDate      DATETIME,
ActivityType     NVARCHAR(2000),
Type             NVARCHAR(2000),
Solution         NVARCHAR(2000),
Reference        NVARCHAR(2000),
STATUS           NVARCHAR(500),
UserName         NVARCHAR(500),
EntityId         BIGINT,
IsActive         BIT,
ActivityEntityId BIGINT,
CreatedTime      DATETIME,
Category         NVARCHAR(2000),
EntityType       NVARCHAR(100),
TransactionName  NVARCHAR(100)
);
CREATE TABLE #ActivitiesForCollectionWorkListQuery
(Id               BIGINT NOT NULL,
Name             NVARCHAR(2000),
ActivityId       BIGINT NOT NULL,
CreatedDate      DATETIME,
ActivityType     NVARCHAR(2000),
Type             NVARCHAR(2000),
Solution         NVARCHAR(2000),
Reference        NVARCHAR(2000),
STATUS           NVARCHAR(500),
UserName         NVARCHAR(500),
EntityId         BIGINT,
IsActive         BIT,
ActivityEntityId BIGINT,
CreatedTime      DATETIME,
Category         NVARCHAR(2000),
EntityType       NVARCHAR(100),
TransactionName  NVARCHAR(100)
);
CREATE TABLE #ActivityDetailsQuery
(Id                      BIGINT NOT NULL,
Name                    NVARCHAR(2000),
ActivityId              BIGINT NOT NULL,
CreatedDate             DATETIME NULL,
ActivityType            NVARCHAR(2000),
Type                    NVARCHAR(2000),
Solution                NVARCHAR(2000),
Reference               NVARCHAR(2000),
STATUS                  NVARCHAR(500),
UserName                NVARCHAR(500),
EntityId                BIGINT,
IsActive                BIT,
ActivityEntityId        BIGINT,
CreatedTime             DATETIMEOFFSET NULL,
Category                NVARCHAR(2000),
ActivityTransactionName NVARCHAR(100),
ActivityEntityName      NVARCHAR(100)
);
INSERT INTO #UserAccessActivityIds
SELECT DISTINCT ActivityId
FROM ActivityPermissions AS actprm
WHERE IsActive = 1
AND actprm.Permission != 'N'
AND UserId = @Userid;
INSERT INTO #UserNonAccessibleActivityIds
SELECT DISTINCT ActivityId
FROM ActivityPermissions AS actprm
WHERE IsActive = 1
AND actprm.Permission != 'N'
AND UserId = @Userid;
INSERT INTO #NonAccessibleActivityIds
SELECT DISTINCT Id
FROM #UserNonAccessibleActivityIds;
INSERT INTO #AccessibleActivityIds
SELECT DISTINCT Id
FROM #UserAccessActivityIds;
INSERT INTO #LoggedInUserNotAssociatedDefaultActivityIdsPrimary
SELECT DISTINCT act.Id
FROM Activities AS act
LEFT JOIN ActivityTypes AS acttype ON act.ActivityTypeId = acttype.Id
LEFT JOIN #AccessibleActivityIds AS acsactids ON act.Id = acsactids.Id
WHERE act.DefaultPermission != 'N';
INSERT INTO #LoggedInUserNotAssociatedDefaultActivityIds
SELECT DISTINCT Id
FROM #LoggedInUserNotAssociatedDefaultActivityIdsPrimary
EXCEPT
SELECT DISTINCT Id
FROM #NonAccessibleActivityIds;
INSERT INTO #UnionOfAccessIdandLoggedInUserNotDef
SELECT DISTINCT Id
FROM #AccessibleActivityIds
UNION
SELECT DISTINCT Id
FROM #LoggedInUserNotAssociatedDefaultActivityIds;
INSERT INTO #ViewableActivityTypeIds
SELECT DISTINCT actype.Id
FROM ActivityTypes AS actype
JOIN ActivityTypeSubSystemDetails AS acypsbstmdt ON actype.Id = acypsbstmdt.ActivityTypeId
JOIN SubSystemConfigs AS sbcng ON acypsbstmdt.SubSystemId = sbcng.id
WHERE sbcng.Name = @CurrentSession
AND acypsbstmdt.Viewable = 1;
INSERT INTO #UserAccessibleActivities
SELECT act.Id,
act.Name,
act.Description,
Solution,
FollowUpDate,
TargetCompletionDate,
act.IsActive,
EntityId,
EntityNaturalId,
act.DefaultPermission,
act.CreatedById,
act.CreatedTime,
act.UpdatedById,
act.UpdatedTime,
OwnerId,
ActivityTypeId,
StatusId,
DocumentListId,
CreatedDate,
CompletionDate,
IsFollowUpRequired,
InitiatedTransactionEntityId,
OwnerGroupId AS bigint
FROM Activities AS act
JOIN #UnionOfAccessIdandLoggedInUserNotDef AS actype ON act.id = actype.Id
LEFT JOIN ActivityTypes AS acttpe ON act.ActivityTypeId = acttpe.Id
WHERE acttpe.Id IS NULL
OR acttpe.id IS NOT NULL
AND acttpe.id IN ( SELECT Id FROM #ViewableActivityTypeIds);
INSERT INTO #ActivitiesForCustomerQuery
SELECT act.Id,
act.Name,
act.Id,
act.CreatedDate,
actype.Name,
actype.Type,
act.Solution,
CASE
WHEN act.InitiatedTransactionEntityId IS NOT NULL
AND act.InitiatedTransactionEntityId > 0
THEN 'Link'
ELSE NULL
END AS InitiatedTransactionEntityId,
actconfig.Name,
usr.FullName,
CASE
WHEN act.EntityId IS NULL
THEN 0
ELSE act.EntityId
END AS EntityId,
act.IsActive,
CASE
WHEN act.InitiatedTransactionEntityId IS NULL
THEN 0
ELSE act.InitiatedTransactionEntityId
END AS InitiatedTransactionEntityId,
act.CreatedTime,
Category,
COALESCE(transactionToBeInitiated.TransactionName, '') AS ActivityTransactionName,
COALESCE(transactionToBeInitiated.EntityType, '') AS ActivityEntityName
FROM #UserAccessibleActivities AS act
JOIN ActivityTypes AS actype ON act.ActivityTypeId = actype.Id
JOIN EntityConfigs AS entconfg ON actype.EntityTypeId = entconfg.Id
JOIN Users AS usr ON act.CreatedById = usr.Id
JOIN ActivityStatusConfigs AS actconfig ON actconfig.Id = act.StatusId
LEFT JOIN ActivityTransactionConfigs AS transactionToBeInitiated ON actype.TransactionTobeInitiatedId = transactionToBeInitiated.Id
WHERE act.EntityId = @CustomerId
AND actype.IsViewableInCustomerSummary = 1
AND entconfg.Name = 'Customer';
INSERT INTO #ActivitiesForCollectionWorkListQuery
SELECT act.Id,
act.Name,
act.Id,
act.CreatedDate,
actype.Name,
actype.Type,
act.Solution,
CASE
WHEN act.InitiatedTransactionEntityId IS NULL
AND act.InitiatedTransactionEntityId > 0
THEN 'Link'
ELSE NULL
END AS InitiatedTransactionEntityId,
actconfig.Name,
usr.FullName,
CASE
WHEN act.EntityId IS NULL
THEN 0
ELSE act.EntityId
END AS EntityId,
act.IsActive,
CASE
WHEN act.InitiatedTransactionEntityId IS NULL
THEN 0
ELSE act.InitiatedTransactionEntityId
END AS InitiatedTransactionEntityId,
act.CreatedTime,
Category,
'' AS ActivityTransactionName,
'' AS ActivityEntityName
FROM #UserAccessibleActivities AS act
JOIN ActivityTypes AS actype ON act.ActivityTypeId = actype.Id
JOIN EntityConfigs AS entconfg ON actype.EntityTypeId = entconfg.Id
JOIN Users AS usr ON act.CreatedById = usr.Id
JOIN ActivityStatusConfigs AS actconfig ON actconfig.Id = act.StatusId
JOIN CollectionWorkLists AS clwrk ON act.EntityId = clwrk.Id
WHERE clwrk.CustomerId = @CustomerId
AND actype.IsViewableInCustomerSummary = 1
AND entconfg.Name = 'CollectionWorkList';
INSERT INTO #ActivityDetailsQuery
SELECT *
FROM #ActivitiesForCollectionWorkListQuery
UNION
SELECT *
FROM #ActivitiesForCustomerQuery;
SELECT AD.Name,
AD.ActivityId,
AD.CreatedDate,
AD.ActivityType,
AD.Type,
AD.Solution,
AD.Reference,
AD.STATUS,
AD.UserName,
AD.EntityId,
AD.IsActive,
AD.ActivityEntityId,
AD.CreatedTime,
AD.Category,
AD.ActivityTransactionName,
AD.ActivityEntityName
FROM #ActivityDetailsQuery AD;
END;

GO
