SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec CloneDBForMigration 'product_intermediate','product_migrationhelper','D:\Migration\',2,1,0,25
Create Procedure [dbo].[CloneDBForMigration]
(
@MasterIntermediateDB sysname
,@MasterHelperDB sysname
,@CloneDBBackupFolderPath nvarchar(1000)
,@TotalNodes tinyint=2
,@StartNode tinyint=1
,@EndNode tinyint=0
,@BatchSizeForConstraintCreation int=25
,@UserId BIGINT
,@CreatedTime  DATETIMEOFFSET
,@ModuleIterationStatusId BIGINT
,@FailedRecords BIGINT OUTPUT
)
AS
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON;
declare @CurrentTime datetimeoffset=SYSDATETIMEOFFSET();
DECLARE @sql NVARCHAR(max)='';
declare @nodeNumber int=1
declare @DBName sysname=DB_Name()
declare @FilePath varchar(2000)
declare @StagingFilePath varchar(2000)
declare @HelperFilePath varchar(2000)
declare @intermediateDBName sysname
declare @HelperDBName sysname
declare @NewDBName sysname
set @FailedRecords=0
if @TotalNodes < 2 or @TotalNodes > 99
	Throw 51000, 'TotalNodes should be between 2 and 99',1;
BEGIN TRY
if @StartNode=1
begin
	delete from Mig_LWTables
	delete from Mig_Constraints
	delete from Mig_TablesRowCounts
	delete from Mig_StagingTableLists
	insert into Mig_LWTables (tableName,MaxId,HasIdentity,CreatedById,CreatedTime,IsMerged) select name,0,OBJECTPROPERTY(OBJECT_ID(name), 'TableHasIdentity'),1,@CurrentTime,0 from sys.tables where type='U' and is_ms_shipped=0;
	exec StoreTablesRowCount;
	delete from Mig_LWTables where tableName in ('ELMAH_Error','Mig_Constraints','Mig_LWTables','CDCResults','CDCAnalysisDetails','CDCRunHistory','CDCTableList','AssetSplitTemp','sysdiagrams','Mig_TablesRowCounts','ParsedString','Mig_MergeLogs','Mig_StagingTableLists');
	SET @sql='';
	SELECT @sql =  @sql + SCH.name + '.' + TBL.name + ' '  
	FROM sys.tables AS TBL INNER JOIN sys.schemas AS SCH ON TBL.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS IDX ON TBL.object_id = IDX.object_id AND IDX.type = 0 -- = Heap 
	INNER JOIN Mig_LWTables AS M on  TBL.name=M.TableName order by M.TableName
	if Len(@sql)>0
	begin
			set @sql='There are tables without primary key : ' + @sql;
			Throw 51001, @sql,1;
	end
	insert into Mig_Constraints(tableName,csql,CreatedById,CreatedTime,IsMerged)
	select tableName, c,1,SYSDATETIMEOFFSET(),0 from(
	select tableName,dbo.GetConstraints('dbo.' + tableName) c from Mig_LWTables)x
	where len(x.c)>0;
	exec DropAllConstraints;
	exec AlterColumnStructure;
	set @sql ='declare @max bigint;'
	select @sql =  @sql + 'select @max=IsNull(max([Id]),0) from ' +  tableName + '; update Mig_LWTables set MaxId=@max where tableName=''' + tableName + ''';' 
	 from Mig_LWTables 
	EXEC sp_executesql @sql;
	exec UpdateToolIdentifier @TotalNodes
	exec DuplicateCatchupJobForClone @TotalNodes
	exec ReSeedDB @TotalNodes,'ly',1,@BatchSizeForConstraintCreation;
	if RIGHT(@CloneDBBackupFolderPath,LEN(@CloneDBBackupFolderPath)-1)!='\'
		set @CloneDBBackupFolderPath=@CloneDBBackupFolderPath + '\';
	set @sql='Exec ' + @DBName + '.dbo.CreateSynonymForTables ''' + @MasterIntermediateDB + ''''
	EXEC sp_executesql @sql	
	set @FilePath=@CloneDBBackupFolderPath + @DBName + '.bak';
	set @StagingFilePath = @CloneDBBackupFolderPath + @MasterIntermediateDB + '.bak';
	set @HelperFilePath = @CloneDBBackupFolderPath + @MasterHelperDB + '.bak';
	BACKUP DATABASE @DBName TO DISK = @FilePath WITH FORMAT,INIT,COMPRESSION;
	BACKUP DATABASE @MasterIntermediateDB TO DISK = @StagingFilePath WITH FORMAT,INIT,COMPRESSION;
	BACKUP DATABASE @MasterHelperDB TO DISK = @HelperFilePath WITH FORMAT,INIT,COMPRESSION;
end
--StartNode & EndNode params are provided in case there is no space in the originating server to clone all instances at once. 
if @StartNode>1 and @StartNode<=@TotalNodes
	set @nodeNumber=@StartNode
if @EndNode<=0 or @EndNode<=@StartNode 
	set @EndNode=@TotalNodes
while @nodeNumber<=@EndNode
begin
	if @nodeNumber=@EndNode
	begin
		set @NewDBName=@DBName
		set @HelperDBName = @MasterHelperDB
	end
	else
	begin
		set @NewDBName=@DBName + cast(@nodeNumber as varchar(2))
		exec master.dbo.sp_CreateDBfromBackup @DBName,@FilePath,@NewDBName
		set @HelperDBName = @MasterHelperDB + cast(@nodeNumber as varchar(2))
		exec master.dbo.sp_CreateDBfromBackup @MasterHelperDB,@HelperFilePath,@HelperDBName
		set @sql='Exec ' + @NewDBName + '.dbo.CreateSynonymForTables ''' + @MasterIntermediateDB + ''''
		EXEC sp_executesql @sql
		set @sql='Exec ' + @NewDBName + '.dbo.CreateSynonymForTables ''' + @HelperDBName + ''''
		EXEC sp_executesql @sql
		set @sql= 'DELETE FROM '+@HelperDBName + '.dbo.processinglogdetail;'
		EXEC sp_executesql @sql;
		set @sql= 'DELETE FROM '+@HelperDBName + '.dbo.processinglog;'
		EXEC sp_executesql @sql;
		set @sql= 'DELETE FROM '+@HelperDBName + '.dbo.Moduleiterationstatus;'
		EXEC sp_executesql @sql;
		set @sql= 'DELETE FROM '+@HelperDBName + '.dbo.Module WHERE ProcessingOrder <= (SELECT ProcessingOrder FROM '+@HelperDBName + '.dbo.Module WHERE  Name = ''CloneDB'');'
		EXEC sp_executesql @sql;
	end	
	set @sql='Exec ' + @NewDBName + '.dbo.CreateExtractTables'
	EXEC sp_executesql @sql
	set @sql='Exec ' + @NewDBName + '.dbo.CreateSynonymForJobs 1'
	EXEC sp_executesql @sql
	set @sql='Exec ' + @NewDBName + '.dbo.CreateSQLJobToCreateExtractTable ''' + @NewDBName +''','+'''development'+ ''''
	EXEC sp_executesql @sql
	set @sql='exec ' + @NewDBName + '.dbo.ResetAllIdentity ' + cast(@nodeNumber as varchar(2))
	EXEC sp_executesql @sql
	set @sql= @sql+'UPDATE '+@HelperDBName + '.dbo.Module SET ToolIdentifier = '+cast(@nodeNumber as varchar(2)) + ' where ProcessingOrder<=(select top 1 ProcessingOrder from '+@HelperDBName + '.dbo.Module where name=''MergeDB'') '
	EXEC sp_executesql @sql;
	DECLARE @MaxId BIGINT;
	SELECT @MaxId = ISNULL(convert(Bigint,s.current_value),1) FROM sys.sequences s WHERE s.Name ='InvoiceNumberGenerator'
	SET @sql = 'USE ' + @NewDBName + '; IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''InvoiceNumberGenerator'') BEGIN ALTER SEQUENCE InvoiceNumberGenerator RESTART WITH ' +  Cast(@MaxId + @nodeNumber as varchar(50)) +  ' INCREMENT BY ' + Cast(@TotalNodes as varchar(50)) + ' END;'
	EXEC sp_executesql @sql
	DECLARE @ReceiptMaxId BIGINT;
	SELECT @ReceiptMaxId = ISNULL(convert(Bigint,s.current_value),1) FROM sys.sequences s WHERE s.Name ='Receipt'
	SET @sql = 'USE ' + @NewDBName + '; IF EXISTS (SELECT * FROM sys.sequences s WHERE s.name =''Receipt'') BEGIN ALTER SEQUENCE Receipt RESTART WITH ' +  Cast(@ReceiptMaxId + @nodeNumber as varchar(50)) +  ' INCREMENT BY ' + Cast(@TotalNodes as varchar(50)) + ' END;'
	EXEC sp_executesql @sql
	set @nodeNumber=@nodeNumber+1
 end
 --node loop ends -- PENDING
END TRY
BEGIN CATCH
Declare @ProcessingLogId Bigint=0;
CREATE TABLE #CreatedProcessingLogs 
		(
			[Id] bigint NOT NULL
		);
INSERT INTO stgProcessingLog
			(
				StagingRootEntityId
				,CreatedById
				,CreatedTime
				,ModuleIterationStatusId
			)
			OUTPUT Inserted.Id into #CreatedProcessingLogs
			VALUES
			(
				0
				,@UserId
				,@CreatedTime
				,@ModuleIterationStatusId
			)
		Set @ProcessingLogId=(select top 1 Id from #CreatedProcessingLogs)
INSERT INTO stgProcessingLogDetail
		(
			Message
			,Type
			,EntityName
			,CreatedById
			,CreatedTime
			,ProcessingLogId
		)
		SELECT
			ERROR_MESSAGE()
			,'Error'
			,'CloneDB'
			,@UserId
			,@CreatedTime
			,@ProcessingLogId
Set @FailedRecords=1;	
DROP TABLE #CreatedProcessingLogs;
END CATCH

GO
