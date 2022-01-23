SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[CreateADLinkedServer]
AS
	declare @userName sysname = system_user

	declare @sqlQuery nvarchar(max)=' 

	USE MASTER
	
	IF NOT EXISTS (SELECT * FROM SYS.SERVERS WHERE NAME LIKE ''ADSI'')
	BEGIN

		EXEC master.dbo.sp_addlinkedserver @server = N''ADSI'', @srvproduct=N''Active Directory Services 2.5'', @provider=N''ADsDSOObject'', @datasrc=N''adsdatasource'', @provstr=N''ADSDSOObject''
		 /* For security reasons the linked server remote logins password is changed with ######## */
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N''ADSI'',@useself=N''True'',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N''ADSI'',@useself=N''True'',@locallogin= @userName,@rmtuser=NULL,@rmtpassword=NULL
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''collation compatible'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''data access'', @optvalue=N''true''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''dist'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''pub'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''rpc'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''rpc out'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''sub'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''connect timeout'', @optvalue=N''0''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''collation name'', @optvalue=null
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''lazy schema validation'', @optvalue=N''false''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''query timeout'', @optvalue=N''0''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''use remote collation'', @optvalue=N''true''
		
		EXEC master.dbo.sp_serveroption @server=N''ADSI'', @optname=N''remote proc transaction promotion'', @optvalue=N''true''

		PRINT ''The linked server ADSI created successfully''
		
	END
	ELSE
	BEGIN
		PRINT ''Could not create linked server! A linked server with the name ADSI already exists!!''
	END
	'
	EXEC SP_ExecuteSQL @sqlQuery
	,N'@userName sysname'
	,@userName

GO
