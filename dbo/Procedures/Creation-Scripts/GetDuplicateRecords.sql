SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create proc [dbo].[GetDuplicateRecords]
as
declare @CurrentDate date
set @CurrentDate=Getdate();
declare @sql nvarchar(max)
set @sql='Use LW_Monitor; if exists(select * from sys.tables where name=''DuplicateRows'') drop table DuplicateRows;'
EXEC SP_ExecuteSQL @sql
select * into #t from
(
Select Min(Id) as Id, count(*) RowsCount,'LeaseFinances-IsCurrent' as Reason from LeaseFinances where IsCurrent=1 group by ContractId having count(*)>1
union all
Select Min(Id) as Id, count(*) RowsCount,'LoanFinances-IsCurrent' as Reason from LoanFinances where IsCurrent=1 group by ContractId having count(*)>1
) x
Select *,@CurrentDate as CreatedTime into LW_Monitor..DuplicateRows from #t

GO
