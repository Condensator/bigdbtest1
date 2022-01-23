SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[BlockUserRoles]
(
@LoginName NVARCHAR(20),
@RoleId RoleIdList READONLY,
@EffectiveDate DATETIMEOFFSET,
@UserId BIGINT,
@CreatedById BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE RolesForUsers SET DeactivationDate=@EffectiveDate, IsActive=0,UpdatedById = @CreatedById,UpdatedTime = @EffectiveDate, IsTemporarilyBlocked = 1
From RolesForUsers
JOIN Roles ON RolesForUsers.RoleId = Roles.Id AND RolesForUsers.IsActive = 1 AND Roles.IsActive = 1
JOIN Users ON RolesForUsers.UserId = Users.Id AND Users.ApprovalStatus = 'Approved'
where Users.LoginName=@LoginName
AND Roles.Id IN (SELECT RoleId FROM @RoleId)
END

GO
