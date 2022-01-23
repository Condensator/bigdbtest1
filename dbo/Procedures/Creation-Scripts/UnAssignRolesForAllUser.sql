SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UnAssignRolesForAllUser]
(
@RoleId RoleIdListForUnAssign READONLY,
@EffectiveDate DATETIMEOFFSET,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE RolesForUsers SET DeactivationDate=@EffectiveDate, IsActive=0,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime, IsTemporarilyBlocked = 1
From RolesForUsers
where RolesForUsers.Id IN (SELECT RoleId FROM @RoleId) AND RolesForUsers.IsActive = 1
END

GO
