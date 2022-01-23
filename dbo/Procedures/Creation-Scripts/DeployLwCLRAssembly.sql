SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Proc [dbo].[DeployLwCLRAssembly]  
(    
@DLLPath nvarchar(260)    
)    
AS    
Begin
Declare @assemblyPath nvarchar(260)=''''+@DLLPath + '''';       
DECLARE @sqlQuery NVARCHAR(max);
      
  IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE NAME='Lw_CLRUser')    
   CREATE USER Lw_CLRUser FOR LOGIN Lw_CLRUser;    
      
  IF OBJECT_ID('dbo.Encrypt') IS NOT NULL    
   Drop function dbo.Encrypt    
  IF OBJECT_ID('dbo.Decrypt') IS NOT NULL    
   Drop function dbo.Decrypt    
  IF OBJECT_ID('dbo.DeprecatedDecrypt') IS NOT NULL    
   Drop function dbo.DeprecatedDecrypt    
  IF OBJECT_ID('dbo.RegexStringMatch') IS NOT NULL    
   Drop function dbo.RegexStringMatch    
    
  if exists(select * from sys.assemblies where name='LwCLR')    
   Drop assembly LwCLR;    
    
  set @sqlQuery='CREATE ASSEMBLY LwCLR FROM ' + @assemblyPath + ' WITH PERMISSION_SET = UNSAFE';    
  EXEC SP_ExecuteSQL @sqlQuery    
    
  UPDATE GlobalParameters SET [Value] = '', [IsActive] = 0 
  WHERE [Category] ='Encryption' AND [Name] ='MasterKey' and IsActive=1    
       
set @sqlQuery='    
CREATE FUNCTION [dbo].[Encrypt]    
(@type NVARCHAR(50), @stringToEncrypt sql_variant NULL, @encryptionKey NVARCHAR (MAX) NULL)    
RETURNS VARBINARY (MAX)    
AS    
EXTERNAL NAME [LwCLR].[EncryptionService].[Encrypt]'    
EXEC SP_ExecuteSQL @sqlQuery    
    
set @sqlQuery='    
CREATE FUNCTION [dbo].[Decrypt]    
(@type NVARCHAR(50), @encryptedText VARBINARY (MAX) NULL, @encryptionKey NVARCHAR (MAX) NULL)    
RETURNS sql_variant    
AS    
EXTERNAL NAME [LwCLR].[EncryptionService].[Decrypt]'    
EXEC SP_ExecuteSQL @sqlQuery    
    
set @sqlQuery='    
CREATE FUNCTION [dbo].[DeprecatedDecrypt]    
(@encryptedText NVARCHAR (MAX) NULL, @encryptionKey NVARCHAR (MAX) NULL)    
RETURNS NVARCHAR (4000)    
AS    
EXTERNAL NAME [LwCLR].[EncryptionService].[DeprecatedDecrypt]'    
EXEC SP_ExecuteSQL @sqlQuery    
    
set @sqlQuery='    
CREATE FUNCTION [dbo].[RegexStringMatch](@stringToCompare [nvarchar](max), @regex [nvarchar](max))    
RETURNS bit    
AS     
EXTERNAL NAME [LwCLR].[EncryptionService].[RegexStringMatch]'    
EXEC SP_ExecuteSQL @sqlQuery  

End

GO
