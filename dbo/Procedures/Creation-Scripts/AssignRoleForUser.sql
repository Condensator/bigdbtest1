SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AssignRoleForUser]
(
@LoginName NVARCHAR(20),
@IsAssigned BIT,
@EffectiveDate DATETIMEOFFSET,
@CreatedById BIGINT,
@RoleId RoleIdsList READONLY,
@UserId BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
INSERT INTO RolesForUsers
([ActivationDate]
,[IsActive]
,[DeactivationDate]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[RoleId]
,[UserId]
,[IsTemporarilyBlocked])
Select @EffectiveDate
,@IsAssigned
,NULL
,@CreatedById
,@CreatedTime
,NULL
,NUll
,RoleIdList.RoleId
,@UserId
,0
From @RoleId [RoleIdList]
END

GO
