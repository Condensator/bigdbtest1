SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
@dbUserName -Format : [Domain\UserName] Or SQLUser
@dbUserPassword - password for the above SQL Login you want to set. Do not set it for Windows user
*/
CREATE PROCEDURE [dbo].[CreateDBUser]
(
	@dbUserName sysname,
	@dbUserPassword NVARCHAR(50)
)
AS
if @dbUserPassword is null
	set @dbUserPassword=''

	DECLARE @sql NVARCHAR(max)= '/*Create User if not exists in the SQL Server*/
		USE [MASTER]
		IF NOT EXISTS(SELECT * FROM sys.server_principals WHERE NAME = ''DBUSERNAME'')
		BEGIN
			if len(@Password)>0
			begin
				CREATE LOGIN DBUSERNAME WITH PASSWORD=N''DBUSERPASSWORD'', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
			end
			else
			begin
				CREATE LOGIN DBUSERNAME FROM WINDOWS WITH DEFAULT_DATABASE=[master]
			end
		END

		/*Create User on the target Database*/
		USE [TARGETDBNAME] 
		IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE NAME=''DBUSERNAME'')
		BEGIN
			CREATE USER DBUSERNAME FOR LOGIN DBUSERNAME WITH DEFAULT_SCHEMA=[dbo]
			GRANT CONNECT,EXECUTE,UnMask TO DBUSERNAME
			ALTER ROLE [db_datareader] ADD MEMBER DBUSERNAME
			ALTER ROLE [db_datawriter] ADD MEMBER DBUSERNAME
		END'

		SET @sql = REPLACE(@sql,'DBUSERNAME',@dbUserName)
		SET @sql = REPLACE(@sql,'DBUSERPASSWORD',@dbUserPassword)
		SET @sql = REPLACE(@sql,'TARGETDBNAME',db_name())
	EXEC SP_ExecuteSQL @sql
	,N'@dbUserName sysname
	,@Password nvarchar(50)'
	,@dbUserName
	,@dbUserPassword

GO
