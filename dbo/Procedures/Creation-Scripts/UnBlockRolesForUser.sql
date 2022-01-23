SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UnBlockRolesForUser]
(
@LoginName NVARCHAR(20),
@RoleId RoleIdLists READONLY,
@EffectiveDate DATETIMEOFFSET,
@UserId BIGINT,
@CreatedById BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE RolesForUsers SET DeactivationDate=NULL, IsActive=1,UpdatedById = @CreatedById,UpdatedTime = @EffectiveDate, IsTemporarilyBlocked = 0
From RolesForUsers
JOIN Roles ON RolesForUsers.RoleId = Roles.Id AND RolesForUsers.IsActive = 1 AND Roles.IsActive = 1
JOIN Users ON RolesForUsers.UserId = Users.Id AND Users.ApprovalStatus = 'Approved'
where Users.LoginName=@LoginName
AND Roles.Id IN (SELECT RoleId FROM @RoleId)
END

GO
