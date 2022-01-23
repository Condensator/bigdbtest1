SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetUserRoleProfileDetail]
(
@LoginName NVARCHAR(MAX)=NULL,
@RoleName NVARCHAR(MAX)=NULL,
@LoginBlocked NVARCHAR(1)=NULL,
@ActiveUser NVARCHAR(1)=NULL,
@AssignmentDate DATETIMEOFFSET=NULL
)
AS
BEGIN
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
WITH CTE_GETLASTLOGOUTTIME
AS
(
SELECT
	UserId,
	MAX(LogoutTime) LastLogoutTime
FROM UserLoginAudits
GROUP BY UserId
)
SELECT
	U.LoginName,
	U.FirstName,
	U.LastName,
	U.ApprovalStatus,
	U.IsWindowsAuthenticated,
	U.ActivationDate,
	LLT.LastLogoutTime,
	U.DeactivationDate,
	R.Name SecurityRoleName,
	RFU.ActivationDate AssignmentDate,
	RFU.DeactivationDate UnAssignmentDate
FROM Users U
	JOIN RolesForUsers RFU ON U.Id = RFU.UserId
	JOIN Roles R ON RFU.RoleId = R.Id
	LEFT JOIN CTE_GETLASTLOGOUTTIME LLT ON U.Id = LLT.UserId
WHERE (@LoginName IS NULL OR U.LoginName LIKE REPLACE(@LoginName,''*'',''%''))
	AND (@RoleName IS NULL OR R.Name LIKE REPLACE(@RoleName,''*'',''%''))
	AND (@AssignmentDate IS NULL OR RFU.ActivationDate = CONVERT(date, @AssignmentDate))
	AND @LoginBlocked = U.IsLoginBlocked
	AND ((@ActiveUser = 1 AND U.ApprovalStatus != ''InActive'') OR (@ActiveUser = 0))'
EXEC sp_executesql @Sql,N'
@LoginName NVARCHAR(MAX),
@RoleName NVARCHAR(MAX),
@LoginBlocked NVARCHAR(1)=NULL,
@ActiveUser NVARCHAR(1)=NULL,
@AssignmentDate DATETIMEOFFSET'
,@LoginName
,@RoleName
,@LoginBlocked
,@ActiveUser
,@AssignmentDate
END

GO
