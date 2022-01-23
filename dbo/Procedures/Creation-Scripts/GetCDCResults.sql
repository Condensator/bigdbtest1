SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [GetCDCResults] @UserName='user.1', @EntityName='appraisalrequests', @ColumnName='comment'

CREATE PROCEDURE [dbo].[GetCDCResults]
(
	@EntityName sysname='%'
	,@EntityId nvarchar(500)='%'
	,@StartDate datetime=null
	,@EndDate datetime='9999-12-01 23:59:59.999'
	,@UserName nvarchar(50)='%'
	,@operationType nvarchar(500)='%'
	,@ColumnName nvarchar(500)='%'
)
as
SET NOCOUNT ON;
create table #result
(
	Uniqueifier INT NOT NULL IDENTITY(1,1)
	,entityName sysname
	,transdt datetime
	,transtype nvarchar(30)
	,oldval nvarchar(max)
	,newval nvarchar(max)
	,loginname nvarchar(50)
	,naturalid nvarchar(1000)
	,cnames nvarchar(max)
	,UNIQUE CLUSTERED (entityName,transdt,transtype, Uniqueifier) 
);
if @EntityName is null
	set @EntityName= '%'
if @EntityId is null
	set @EntityId= '%'
else
begin
	set @EntityId=Replace(@EntityId,'''','''''')
	set @EntityId=Replace(@EntityId,'--','')
	set @EntityId=Replace(@EntityId,'/*','')
	set @EntityId=Replace(@EntityId,'*','%')
end
if @StartDate is null
	set @StartDate= cast((-53690) as datetime)
if @EndDate is null
	set @EndDate= '9999-12-01 23:59:59.999'
if @UserName is null
	set @UserName= '%'
if (@operationType is NULL OR @operationType='_')
	set @operationType= '%'
if @ColumnName is null
	set @ColumnName= '%'
	 
Declare @opertype nvarchar(20)='%'
if @operationType='DELETE'
	set @opertype='1'
else if @operationType='INSERT'
	set @opertype='2'
if @operationType='UPDATE'
	set @opertype='3'

set @ColumnName= REPLACE(@ColumnName, ',', '@@@@')

-- Return results of only one table
insert into 
	#result(
	entityName 
	,transdt
	,transtype
	,oldval
	,newval
	,loginname
	,naturalid
	,cnames)
select	replace(t.entityname,'_CT','')  
		,transdt 
		,CASE transtype 
				WHEN 1 THEN 'Delete'
				WHEN 2 THEN 'Insert'
				WHEN 3 THEN 'Update'
			END 
		,oldval
		,newval
		,u.loginname
		,c.naturalId 
		,c.columnnames as cnames 
from CDC_CDCResults c 
		join CDC_CDCTableList t 
			on c.TableCounterId=t.[TableCounterId] 
		left outer join dbo.users u 
			on c.modifiedBy = u.id 
where 
replace(t.entityname,'_CT','') like @EntityName 
and transDt >= @StartDate 
and transDt <= @EndDate
and ((u.LoginName is null and @UserName='%') or u.LoginName like @UserName)
and (@EntityId='%' or c.naturalId like @EntityId)
and cast(transtype as varchar) like @opertype  


if @ColumnName != '%'
BEGIN
	delete #result where cnames not like '%'+@ColumnName+'%'
	update  #result set  cnames=@ColumnName
end

UPDATE CI SET CI.entityname  = U.userfriendlyname 
   FROM #result CI INNER JOIN DBO.AuditEntityConfigs U ON U.TableName=CI.entityname;

select 
	replace(entityname,'_CT','')  'Entity Name'
	,transdt 'Transaction Time'
	,transtype [operation]
	,dbo.CDC_GetCombinedChangedData(oldval,newval,cnames) 'Consolidated Changed'
	,naturalid 'Entity ID'
	,loginname 'Changed_By'
from #result 
order by transdt desc

GO
