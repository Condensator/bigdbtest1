SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create   proc [dbo].[GetUnUsedTables](@UnusedMonths int=6)
as
declare @CurrentDate date
set @CurrentDate=Getdate();

Create table #t
(TableName sysname not null,
reason varchar(50) not null
)

insert into #t(TableName,Reason)
Select TableName,'ZeroRows' from
(
select Min(t.name) TableName,sum(p.rows) as RowsCount
from sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
inner join sys.schemas s on t.schema_id=s.schema_id and s.name='dbo'
WHERE  i.OBJECT_ID > 255 AND  i.index_id <= 1
GROUP BY t.object_id,i.object_id, i.index_id
)x
where x.RowsCount=0

insert into #t(TableName,Reason)
SELECT  OBJECT_NAME(object_Id),'NotUsedSinceStartup' from
(select s.object_Id,(s.user_seeks+s.user_lookups+s.user_scans+s.user_updates) as hits
FROM sys.dm_db_index_usage_stats s
WHERE [database_id] = DB_ID() 
) x
group by x.object_Id having sum(hits)<3
--user_scan is usually set to 1 for some weird reason; accounting for 1 more (and hence hits<3 condition) incase of any unique index on the table

begin try
	select dbo.Pluralize(Entityname) as TableName into #x from MasterConfigEntities

	insert into #t(TableName,Reason)
	SELECT OBJECT_NAME(s.object_Id),'NoUpsert' FROM sys.dm_db_index_usage_stats s
	 join sys.indexes i on s.object_id=i.object_id and s.index_id=i.index_id and i.type=1 and i.OBJECT_ID > 255
WHERE [database_id] = DB_ID() and OBJECT_NAME(s.object_Id) not in (select TableName from #x) and s.user_updates=0
end try
BEGIN CATCH
	--swallow the error saying SQL Full text search is turned off
END CATCH

delete from #t where reason='NoUpsert' and TableName in (select tablename from #t where reason<>'NoUpsert')

insert into LW_Monitor..TableInfo (TableName,Reason,CreatedDate)
select TableName,Reason,@CurrentDate from #t

GO
