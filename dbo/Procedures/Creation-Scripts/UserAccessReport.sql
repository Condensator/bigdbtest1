SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UserAccessReport]
(
@UserId BIGINT = NULL,
@LoginName NVARCHAR(50) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #RoleDetails  (TempUserId BIGINT, RoleName NVARCHAR(80) , OverrideLevel INT , RowNumber INT, LoginName NVARCHAR(40), FullName NVARCHAR(500), ActivationDate DATE, DeactivationDate DATE)
CREATE TABLE #UserLogTable (UserId BIGINT,AuditSourceId BIGINT,DeactivationDate DATE,AuditLogId BIGINT)
CREATE TABLE #ResultTable (UserId BIGINT,AuditSourceId BIGINT,DeactivationDate DATE,AuditLogId BIGINT)
CREATE TABLE #AuthorityLimitDetails (UserId BIGINT,Limit_Amount DECIMAL(24, 2),Limit_Currency VARCHAR(3),Name NVARCHAR(100),CreatedTime DATE,Deactivation DATE,RNumber INT);
INSERT INTO #RoleDetails (TempUserId,RoleName,OverrideLevel,LoginName,FullName,ActivationDate,DeactivationDate, RowNumber)
SELECT u.Id,Role=r.Name,r.ValidationOverrideLevel,u.LoginName,u.FullName,rfu.ActivationDate,rfu.DeactivationDate,RowNumber = ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY r.Name, rfu.ActivationDate Desc) FROM Users u
JOIN RolesForUsers rfu ON u.Id = rfu.UserId
JOIN Roles r on rfu.RoleId = r.Id
WHERE u.ApprovalStatus != 'Inactive' AND (@UserId IS NULL OR u.Id = @UserId) ORDER BY r.Name
INSERT INTO #UserLogTable(UserId,AuditSourceId,DeactivationDate,AuditLogId)
SELECT a.UserId,a.AuditSourceId,null,a.Id FROM UserAuthorityLimitAuditLogs a WHERE (@UserId IS NULL OR a.UserId = @UserId)
INSERT INTO #ResultTable(UserId,AuditSourceId,DeactivationDate,AuditLogId)
SELECT u.UserId,u.AuditSourceId,u.CreatedTime,u.Id FROM UserAuthorityLimitAuditLogs u
JOIN #UserLogTable b ON u.AuditSourceId = b.AuditSourceId AND u.Id = b.AuditLogId
UPDATE #ResultTable SET DeactivationDate = (SELECT TOP 1 s.CreatedTime FROM UserAuthorityLimitAuditLogs s WHERE s.Id > r.AuditLogId AND s.AuditSourceId = r.AuditSourceId)
FROM #ResultTable r
DECLARE @CountValue INT , @AuditSourceId BIGINT;
DECLARE loop_Cursor  CURSOR FOR
SELECT AuditSourceId,[Count]=COUNT(*) FROM UserAuthorityLimitAuditLogs
GROUP BY AuditSourceId ;
OPEN loop_Cursor;
FETCH NEXT FROM loop_Cursor INTO @AuditSourceId, @CountValue;
WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @MaxId BIGINT = 0;
DECLARE @MinId BIGINT = 0;
DECLARE @MaxPlusOneId BIGINT = 0;
DECLARE @IsActive BIT = 0;
SET @MaxId = (SELECT MAX(Id) FROM UserAuthorityLimitAuditLogs WHERE AuditSourceId = @AuditSourceId);
SET @IsActive = (SELECT IsActive FROM UserAuthorityLimitAuditLogs WHERE Id = @MaxId);
SET @MinId = (SELECT MIN(Id) FROM UserAuthorityLimitAuditLogs WHERE AuditSourceId = @AuditSourceId);
IF (@IsActive = 0) BEGIN SET @MaxPlusOneId = @MaxId +1; END
ELSE BEGIN SET @MaxId = @MaxId; END
IF @CountValue > 1
BEGIN
UPDATE #UserLogTable SET DeactivationDate = logTable.DeactivationDate
FROM #UserLogTable tempTable
JOIN #ResultTable logTable ON tempTable.AuditSourceId = logTable.AuditSourceId AND tempTable.AuditLogId = logTable.AuditLogId
WHERE logTable.AuditLogId < @MaxId AND logTable.AuditLogId >= @MinId
END
FETCH NEXT FROM loop_Cursor into @AuditSourceId, @CountValue;
END
CLOSE loop_Cursor;
DEALLOCATE loop_Cursor;
INSERT INTO #AuthorityLimitDetails (UserId,Limit_Amount,Limit_Currency,NAME,CreatedTime,Deactivation,RNumber)
SELECT ualh.UserId,ualh.Limit_Amount,ualh.Limit_Currency, ISNULL(EntityResourcesForAuthority.Value,a.Name),ualh.CreatedTime,Deactivation = cte.DeactivationDate,RNumber = ROW_NUMBER() OVER (PARTITION BY ualh.UserId ORDER BY ISNULL(EntityResourcesForAuthority.Value,a.Name), ualh.CreatedTime DESC) FROM UserAuthorityLimitAuditLogs ualh
JOIN Authorities a ON ualh.AuthorityId = a.Id
LEFT JOIN EntityResources EntityResourcesForAuthority on EntityResourcesForAuthority.EntityId=a.Id
AND EntityResourcesForAuthority.Entitytype='Authority'
AND EntityResourcesForAuthority.Name='Name'
AND EntityResourcesForAuthority.Culture=@Culture
LEFT JOIN #UserLogTable cte ON ualh.Id = cte.AuditLogId
WHERE (@UserId IS NULL OR ualh.UserId = @UserId) AND ualh.IsActive = 1
ORDER BY ISNULL(EntityResourcesForAuthority.Value,a.Name)
SELECT u.FullName,u.LoginName,Role=rd.RoleName,ValidationOverrideLevel=rd.OverrideLevel,rd.ActivationDate,rd.DeactivationDate,Authority=ald.Name,ald.Limit_Amount,ald.Limit_Currency,ald.CreatedTime,ald.Deactivation,InternalSorting= ROW_NUMBER() OVER(PARTITION BY u.FullName ORDER BY rd.RoleName,ald.Name) FROM #AuthorityLimitDetails ald
FULL JOIN #RoleDetails rd ON ald.UserId = rd.TempUserId AND ald.RNumber = rd.RowNumber
JOIN Users u ON (u.Id = rd.TempUserId OR u.Id = ald.UserId)
WHERE (@LoginName IS NULL OR u.LoginName = @LoginName)
ORDER BY u.FullName, CASE WHEN rd.RoleName IS NULL THEN 1 ELSE 0 END, CASE WHEN ald.Name IS NULL THEN 1 ELSE 0 END
DROP TABLE #RoleDetails
DROP TABLE #UserLogTable
DROP TABLE #ResultTable
DROP TABLE #AuthorityLimitDetails
END

GO
