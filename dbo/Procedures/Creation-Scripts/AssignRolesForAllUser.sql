SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AssignRolesForAllUser]
(
@RoleId RoleIdListForAssign READONLY,
@EffectiveDate DATETIMEOFFSET,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE RolesForUsers SET DeactivationDate=NULL, IsActive=1,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime, IsTemporarilyBlocked = 0
FROM RolesForUsers
WHERE RolesForUsers.Id IN (SELECT RoleId FROM @RoleId)
AND IsTemporarilyBlocked = 1
END

GO
