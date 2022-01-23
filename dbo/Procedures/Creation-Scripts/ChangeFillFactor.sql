SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--Options for Compression: NONE | ROW | PAGE
Create   proc [dbo].[ChangeFillFactor]
(@Compression nvarchar(10)='NONE')
as      
set nocount on;      
Declare @IndexName sysname,@TableName sysname,@sql nvarchar(2000),@ff tinyint,@AffectedCount int;

set @AffectedCount=0
declare @t table (type tinyint not null,ff tinyint not null)
insert into @t(type,ff) values(1,97)
insert into @t(type,ff) values(2,90)

declare cur cursor for
SELECT i.name as IndexName,o.name as TableName, t.ff
from sys.tables o
join sys.indexes i on i.object_id = o.object_id
join @t t on i.type=t.type
and o.is_ms_shipped = 0 
and i.fill_factor!=t.ff  
and i.is_disabled=0 and i.index_id>0 and auto_created=0
order by o.name

open cur
Fetch next from cur into @IndexName,@TableName,@ff
While (@@fetch_status <> -1)
Begin 
	
	set @sql = 'ALTER INDEX ['+ cast (@IndexName as nvarchar(140))+'] ON dbo.['+cast (@TableName as nvarchar(140))+'] REBUILD PARTITION = ALL WITH (FILLFACTOR =' + cast(@ff as varchar(5)) + ', MAXDOP=0,DATA_COMPRESSION = ' + @Compression + ')'
	Exec sp_executesql @sql  
	set @AffectedCount=@AffectedCount+1

	Fetch next from cur into @IndexName,@TableName,@ff
End
close cur
deallocate cur
print cast(@AffectedCount as varchar(20))

GO
