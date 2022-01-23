SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateUsersFromAD]
AS
Declare @sqlQuery nvarchar(max) = '
--Fetch all the active directory users from
Create Table #ADActiveUsers
(
Id int Identity(1,1) primary key,
FirstName nvarchar(100) not null,
LastName nvarchar(100) not null,
FullName nvarchar(200) not null,
LoginName nvarchar(100) not null,
EmailId nvarchar(100) not null,
ContactNumber nvarchar(25) not null
)
Insert into #ADActiveUsers (firstname,LastName,LoginName,FullName,EmailId,contactNumber)
SELECT
givenName AS FirstName,
sn AS LastName,
samAccountName AS LoginName,
displayName AS FullName,
userprincipalname AS EmailId,
isnull(telephoneNumber,'''') AS ContactNumber
FROM OPENQUERY
(ADSI
,''
SELECT
userPrincipalName,
samAccountName,
telephoneNumber,
mail,
givenName,
sn,
displayName
FROM ''''LDAP://odessapdc01/DC=odessapdc01,DC=com''''
WHERE objectCategory = ''''Person'''' and ObjectClass=''''User''''
AND ''''userAccountControl:1.2.840.113556.1.4.803:''''<>2
'') as ADData
WHERE sn IS NOT NULL AND mail IS NOT NULL AND givenName IS NOT NULL
and samAccountName not in (select loginname from users)-- where IsWindowsAuthenticated =1 and ApprovalStatus=''Approved'')
ORDER BY samAccountName
declare @maxUserCount int = (select max(id) from #ADActiveUsers)
declare @loopVar int = 1
declare @userId int = 0
WHILE(@loopVar <= @maxUserCount)
BEGIN
--insert into users table.
INSERT Users
(FirstName, LastName,FullName, LoginName, IsWindowsAuthenticated, Email, IsEmailNotificationAllowed, LoginEffectiveDate, IsLoginBlocked,
IsAdminBlocked, ForcePasswordReset, CreationDate, ActivationDate, CanLogin, LoginFailureCounter, ApprovalStatus, CreatedById, CreatedTime,
UserType, IsFactorAuthenticationEnabled, IsFactorAuthorizationEnabled,IsFullAccess)
SELECT
FirstName,ISNULL(LastName,''''),FullName, LoginName, 1, EmailId, 0, CAST(GETDATE() AS Date), 0, 0, 0, CAST(GETDATE() AS Date),
CAST(GETDATE() AS Date), 1, 0, N''Approved'', 2, SYSDATETIMEOFFSET(), N''LW'', 0, 0,1
FROM #ADActiveUsers where Id = @loopVar
set @userId = SCOPE_IDENTITY()
IF @userId IS NOT NULL
Begin
--insert into usersiteaccesses table.
INSERT UserSiteAccesses (IsActive, CreatedById, CreatedTime, SiteConfigId, UserId)
SELECT 1, 2,SYSDATETIMEOFFSET(), 1, @userId
--insert into rolesforusers table.
INSERT RolesForUsers (ActivationDate, IsActive, CreatedById, CreatedTime, RoleId, UserId, IsTemporarilyBlocked)
SELECT CAST(GETDATE() AS Date), 1, 2,SYSDATETIMEOFFSET(), 2, @userId,0
--insert into legalentitiesforusers table. (insert all the active legal entity records for each user)
INSERT LegalEntitiesForUsers  (ActivationDate, IsActive, IsDefault, CreatedById, CreatedTime, LegalEntityId, UserId)
SELECT CAST(GETDATE() AS Date), 1, 1, 2, SYSDATETIMEOFFSET(), id, @userId FROM LegalEntities WHERE [status]=''Active''
--insert into UserEmailAddresses table.
INSERT UserEmailAddresses (Email, IsPrimary, IsActive, UserId, CreatedById, CreatedTime)
SELECT EmailId,1,1,@userId,2,SYSDATETIMEOFFSET() FROM #ADActiveUsers where Id = @loopVar
END
SET @loopVar = @loopvar+1
END
DROP TABLE #ADActiveUsers'
Exec sp_executesql @sqlQuery

GO
