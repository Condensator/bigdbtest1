SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create proc [dbo].[ReSeedDB]
(
@SeedIncrement tinyint
,@Prefix varchar(2)='ly'
,@UserId bigint
,@BatchSizeForConstraintCreation int
)
as
DECLARE @sql NVARCHAR(max)=''  
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('CreateTableStructure started',1,SYSDATETIMEOFFSET());
select @sql =  @sql + 'exec CreateTableStructure ''dbo.'+ tableName +''',' + Cast(@SeedIncrement as varchar(2)) + ',''' + @Prefix + tableName + ''';'  
from Mig_LWTables  
EXEC sp_executesql @sql; 
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('CreateTableStructure completed',1,SYSDATETIMEOFFSET());
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('switch to started',1,SYSDATETIMEOFFSET());
set @sql =''  
select @sql =  @sql + 'alter table dbo.' + tableName +' SWITCH TO dbo.' + @Prefix + tableName + ';'  
from Mig_LWTables
EXEC sp_executesql @sql;  
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('switch to complete',1,SYSDATETIMEOFFSET());
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('drop table started',1,SYSDATETIMEOFFSET());
set @sql =''  
select @sql =  @sql + 'drop table dbo.' + tableName+';'  
from Mig_LWTables  
EXEC sp_executesql @sql;
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('drop table complete',1,SYSDATETIMEOFFSET()); 
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('rename started',1,SYSDATETIMEOFFSET());   
set @sql =''  
select @sql =  @SQL + 'exec sp_rename ' + '''dbo.' + @Prefix + tableName+''',''' + tableName+ ''';'  
from Mig_LWTables  
EXEC sp_executesql @sql; 
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('rename completed',1,SYSDATETIMEOFFSET()); 
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('constraint started',1,SYSDATETIMEOFFSET());      
--re create constraints  
declare @RemainingRowCount bigint = 0
select @RemainingRowCount = count(*) from Mig_Constraints where IsMerged = 0

while @RemainingRowCount > 0
begin
begin try
set @sql =''
select top (@BatchSizeForConstraintCreation) @sql = @sql + csql + '; update Mig_Constraints set IsMerged=1,UpdatedTime = sysdatetimeoffset(),UpdatedById = '+ cast(@UserId as varchar)+ '  where Id='+cast(Mig_Constraints.id as varchar)+'; '
from Mig_Constraints join Mig_LWTables on Mig_Constraints.TableName = Mig_LWTables.TableName where Mig_Constraints.IsMerged=0 and maxid < 1000000 order by maxid
-- When we merge last db, we need to update it with current maxId

if @@RowCount = 0 
select top 1 @sql = @sql + csql + '; update Mig_Constraints set IsMerged=1,UpdatedTime = sysdatetimeoffset(),UpdatedById = '+ cast(@UserId as varchar)+' where Id='+cast(Mig_Constraints.id as varchar)+';'
from Mig_Constraints join Mig_LWTables on Mig_Constraints.TableName = Mig_LWTables.TableName where Mig_Constraints.IsMerged=0 order by maxid
EXEC sp_executesql @sql
select @RemainingRowCount = count(ID) from Mig_Constraints where IsMerged=0
end try
begin catch
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values (Error_Message(),1,SYSDATETIMEOFFSET()); 
Declare @err_msg as nvarchar(max);
set @err_msg=Error_Message();
Throw 51000, @err_msg,1;
end catch
end 
insert into Mig_MergeLogs (LogMessage,CreatedById,CreatedTime) values ('constraint completed',1,SYSDATETIMEOFFSET());

GO
