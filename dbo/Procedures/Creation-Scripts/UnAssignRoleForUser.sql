SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UnAssignRoleForUser]
(
@LoginName NVARCHAR(20),
@IsAssigned BIT,
@RoleName RoleNameList READONLY,
@EffectiveDate DATETIMEOFFSET,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE RolesForUsers SET DeactivationDate=@EffectiveDate, IsActive=@IsAssigned,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
From RolesForUsers
JOIN Roles ON RolesForUsers.RoleId = Roles.Id AND RolesForUsers.IsActive = 1 AND Roles.IsActive = 1
JOIN Users ON RolesForUsers.UserId = Users.Id AND Users.ApprovalStatus = 'Approved'
where Users.LoginName=@LoginName
AND Roles.Name in (Select RoleName from @RoleName)
END

GO
