SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[EnableDisabledConstraints]
as
declare @sql nvarchar(max)='';
SELECT @sql=@sql+ 'ALTER TABLE ' + o.name + ' WITH CHECK CHECK CONSTRAINT [' + i.name + '];'
from sys.check_constraints i
INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0;
EXEC sys.sp_executesql @sql;
declare cur cursor for
SELECT 'ALTER TABLE ' + o.name + ' WITH CHECK CHECK CONSTRAINT [' + i.name + '];' as s
from sys.foreign_keys i
INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0;
open cur
fetch next from cur into @sql
while @@FETCH_STATUS=0
begin
begin try
EXEC sys.sp_executesql @sql;
end try
begin catch
print @sql + ' failed'
end catch
fetch next from cur into @sql
end
close cur
deallocate cur

GO
