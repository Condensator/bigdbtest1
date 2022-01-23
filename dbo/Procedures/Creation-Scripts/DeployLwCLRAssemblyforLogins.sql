SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Proc [dbo].[DeployLwCLRAssemblyforLogins]  
(    
 @KeyPath nvarchar(260)    
,@KeyPassword nvarchar(100)    
)    
AS    
Begin
declare @snkPath nvarchar(260)=''''+@KeyPath + '''';    
declare @keyPass nvarchar(100)=''''+@KeyPassword + '''';    
 
DECLARE @LoginName Nvarchar(50);    
DECLARE @UserName Nvarchar(50);    

DECLARE @sqlQuery NVARCHAR(max)= '    
  USE [MASTER]    
      
  EXEC sp_configure ''show advanced options'', 1;    
  RECONFIGURE;    
  EXEC sp_configure ''clr enabled'', 1;    
  RECONFIGURE;    
    
  IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = ''Lw_CLRSqlServicesKey'')    
   CREATE ASYMMETRIC KEY Lw_CLRSqlServicesKey FROM FILE = ' + @snkPath + ' ENCRYPTION BY PASSWORD=' + @keyPass + ';    
  IF NOT EXISTS(SELECT * FROM  sys.server_principals WHERE NAME = ''Lw_CLRUser'')    
   CREATE LOGIN Lw_CLRUser FROM ASYMMETRIC KEY Lw_CLRSqlServicesKey;    
  GRANT UNSAFE ASSEMBLY TO Lw_CLRUser;'    
      
  EXEC SP_ExecuteSQL @sqlQuery    

End

GO
