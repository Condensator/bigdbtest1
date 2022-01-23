SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[MergeTableFromIdenticalDB]
(@tableNameWithSchema sysname
,@SourceDBName sysname
,@PreMigrationMaxId bigint
,@HasIdentity bit
)
as
DECLARE  
@object_id INT  
, @StringLength int
, @RemainingDataCount bigint

DECLARE @ColsCSV NVARCHAR(max)=''  
DECLARE @sql NVARCHAR(max)='' 
declare @ParmDefinition nvarchar(50); 
declare @batchSize bigint = 250000;

SELECT  
	@object_id = o.[object_id]  
FROM sys.objects o WITH (NOWAIT)  
JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]  
WHERE 
	s.name + '.' + o.name = @tableNameWithSchema  
	AND o.[type] = 'U'  
	AND o.is_ms_shipped = 0  

--select all columns except timestamp (RowVersion)  
select @ColsCSV =  @ColsCSV + '[' + c.name + '],' FROM sys.columns c WITH (NOWAIT)  
JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id  
WHERE c.[object_id] = @object_id  
and c.is_computed=0 and c.user_type_id<> 189  
ORDER BY c.column_id  
set @StringLength=len(@ColsCSV) 
declare @ParmDefinitionInsert nvarchar(100);
declare @sqlInsert nvarchar(max) = 'select @countOUT = Count(Id) from ' + @SourceDBName + '.'+@tableNameWithSchema+ '  Where [Id]>' + Cast(@PreMigrationMaxId as varchar(100)) +';'
SET @ParmDefinitionInsert = N'@countOUT bigint OUTPUT';
Exec sp_executesql @sqlInsert,@ParmDefinitionInsert,@countOUT=@RemainingDataCount OUTPUT

if @StringLength>1   
begin  
	--removing last comma  
	set @ColsCSV=LEFT(@ColsCSV,@StringLength-1)  
end

SET @ParmDefinition = N'@maxId bigint OUTPUT';
declare @StartTimeUpdateSQL nvarchar(max) = 'update ' + @SourceDBName + '.dbo.Mig_LWTables set StartTime = ''' + CAST(SYSDATETIMEOFFSET() AS nvarchar(200)) + ''' where TableName = ''' + RIGHT(@tableNameWithSchema,LEN(@tableNameWithSchema)-4) + ''';'
Exec sp_executesql @StartTimeUpdateSQL
while @RemainingDataCount > 0 
begin
	set @sql = 'create table #temp(id bigint);';
	if @HasIdentity=1 
		set @sql= @sql + 'SET IDENTITY_INSERT '+@tableNameWithSchema+ ' ON;'
	select @sql= @sql + 'SET NOCOUNT ON; Insert into '+@tableNameWithSchema+ ' (' + @ColsCSV + ') OUTPUT(Inserted.Id) into #temp select top ' +CAST(@batchSize as nvarchar(50))+' '+ @ColsCSV + ' From ' + @SourceDBName + '.'+@tableNameWithSchema+ '  Where [Id]>' + Cast(@PreMigrationMaxId as varchar(100)) + ' order by Id OPTION (MAXDOP 1); select @maxid =  max(id) from #temp;drop table #temp;'  
	if @HasIdentity=1 
		set @sql= @sql + 'SET IDENTITY_INSERT '+@tableNameWithSchema+ ' OFF;'

	BEGIN TRY 
		EXEC sp_executesql @sql,@ParmDefinition,@maxId=@PreMigrationMaxId OUTPUT
	END TRY
	BEGIN CATCH
		insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values (ERROR_MESSAGE() ,1,SYSDATETIMEOFFSET());
		DECLARE @ErrorMessage Nvarchar(max);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorMessage=ERROR_MESSAGE()
		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH;
	--insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values (@SourceDBName  + ' '+ @tableNameWithSchema +' :PreMigrationMaxId : ' + CAST(@PreMigrationMaxId AS NVARCHAR(100)) ,1,SYSDATETIMEOFFSET()); 
	SET @RemainingDataCount = @RemainingDataCount - @batchSize;
end

declare @EndTimeUpdateSQL nvarchar(max) = 'update ' + @SourceDBName + '.dbo.Mig_LWTables set IsMerged = 1 ,EndTime = ''' + CAST(SYSDATETIMEOFFSET() AS nvarchar(200)) + ''' where TableName = ''' + RIGHT(@tableNameWithSchema,LEN(@tableNameWithSchema)-4) + ''';'
Exec sp_executesql @EndTimeUpdateSQL

GO
