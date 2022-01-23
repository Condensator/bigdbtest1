SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[EnableAuditing]
(
 @LWDBUserName sysname
)
As
declare @LwDatabaseName sysname
declare @SQL nvarchar(max);
select @LwDatabaseName=DB_NAME()
	
if exists(SELECT * FROM sys.databases WHERE is_cdc_enabled = 0 AND name = @LwDatabaseName)
begin
	EXEC sys.sp_cdc_enable_db;
end

if not exists(SELECT * FROM sys.database_principals WHERE name ='cdc_admin')
begin
	CREATE ROLE [cdc_admin];
End

EXEC sp_configure 'show advanced options', 1 ; 
RECONFIGURE ; 
EXEC sp_configure 'max text repl size', -1 ; 
RECONFIGURE; 

exec EnableCDCForTables 1;

set @SQL=	'GRANT IMPERSONATE ON User::cdc TO '+ @LWDBUserName 
			+';grant execute to '+@LWDBUserName;
exec sp_executesql @SQL;


GO
