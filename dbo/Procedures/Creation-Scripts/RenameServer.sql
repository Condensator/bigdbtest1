SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[RenameServer]
as
	declare @SQLServerName nvarchar(250)= (SELECT srvname FROM master.dbo.sysservers where srvname like @@SERVERNAME)
	declare @SystemName sql_variant= (SELECT SERVERPROPERTY('ServerName'))
	IF(@SQLServerName != @SystemName)
	begin
		declare @Sql nvarchar(500);
		set @Sql = 'sp_dropserver ''' + @SQLServerName + ''''
		EXEC sp_executesql @Sql
		set @Sql = 'sp_addserver'''+cast(@SystemName as nvarchar(250))+''',local';
		EXEC sp_executesql @Sql
	end

GO
