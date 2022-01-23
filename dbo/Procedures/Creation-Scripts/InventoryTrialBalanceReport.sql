SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InventoryTrialBalanceReport]
@SequenceNumber NVARCHAR(40),
@IncomeDate AS Date,
@LegalEntityName NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON
declare @AccumulateDepreciationForCapitalLeases BIT;
set @AccumulateDepreciationForCapitalLeases = case when (select Value from GlobalParameters where Name = 'AccumulateDepreciationForCapitalLeases') = 'true' then 1 else 0 end;
IF @AccumulateDepreciationForCapitalLeases = 1
begin
create table #MaximumComponent(
  AVHId BIGINT,
);
create table #MinimumComponent(
  AVHId BIGINT,
); 
with cte_maximumcomponent(AVHId,SourceModule,AssetId,IsLeaseComponent) as(
select MAX(AssetValueHistories.Id) as 'AVHId',AssetValueHistories.SourceModule,AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent from AssetValueHistories
 where AssetValueHistories.incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
 group by AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent,AssetValueHistories.SourceModule
)
insert into #MaximumComponent
select max(AVHId) from cte_maximumcomponent where IsLeaseComponent=1
group by AssetId,IsLeaseComponent
 union
 select max(AVHId) from cte_maximumcomponent where IsLeaseComponent=0
group by AssetId,IsLeaseComponent;

with cte_minimumcomponent(AVHId,SourceModule,AssetId,IsLeaseComponent)as(
select MIN(AssetValueHistories.Id) as 'AVHId',AssetValueHistories.SourceModule,AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent from AssetValueHistories
 where AssetValueHistories.incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
 group by AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent,AssetValueHistories.SourceModule
)
insert into #MinimumComponent
 select min(AVHId) from cte_minimumcomponent where IsLeaseComponent=1
group by AssetId,IsLeaseComponent
 union
 select min(AVHId) from cte_minimumcomponent where IsLeaseComponent=0
group by AssetId,IsLeaseComponent;

 select AssetValueHistories.AssetId,Sum(AssetValueHistories.Value_Amount) AS 'Value_Amount',MAX(AssetValueHistories.Value_Currency) AS 'Value_Currency', Sum(EndBookValue_Amount) AS 'EndBookValue_Amount',MAX(AssetValueHistories.EndBookValue_Currency) AS 'EndBookValue_Currency' into #MaximumComponentValues from AssetValueHistories 
 join #MaximumComponent on AssetValueHistories.Id = #MaximumComponent.AVHId
 where AssetValueHistories.IsLessorOwned=1
 group by AssetValueHistories.AssetId

 select AssetValueHistories.AssetId,Sum(AssetValueHistories.Cost_Amount) AS 'Cost_Amount',MAX(AssetValueHistories.Cost_Currency) AS 'Cost_Currency' into #MinimumComponentValues from AssetValueHistories 
 join #MinimumComponent on AssetValueHistories.Id = #MinimumComponent.AVHId
 where AssetValueHistories.IsLessorOwned=1
 group by AssetValueHistories.AssetId

 SELECT 
#MaximumComponentValues.AssetId ,
#MaximumComponentValues.Value_Amount,
#MaximumComponentValues.Value_Currency,
#MinimumComponentValues.Cost_Amount,
#MinimumComponentValues.Cost_Currency,
#MaximumComponentValues.EndBookValue_Amount,
#MaximumComponentValues.EndBookValue_Currency
INTO #ComponentCollection
FROM #MaximumComponentValues
JOIN #MinimumComponentValues
on #MaximumComponentValues.AssetId = #MinimumComponentValues.AssetId

SELECT AssetValueHistories.AssetId ,
sum(AssetValueHistories.Value_Amount) as 'Accumulated Depreciation',
MAX(AssetValueHistories.Value_Currency) as 'Accumulated Depreciation Currency'
INTO #ComponentSum
FROM AssetValueHistories
WHERE incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
and AssetValueHistories.IsLessorOwned=1
GROUP BY AssetValueHistories.AssetId

SELECT
contracts.SequenceNumber,
#ComponentCollection.AssetId as 'Asset Id' ,
#ComponentCollection.Cost_Amount as 'Initial Cost',
#ComponentCollection.Cost_Currency as 'Initial Cost Currency',
#ComponentCollection.Value_Amount as 'Book Depriciation' ,
#ComponentCollection.Value_Currency as 'Book Depriciation Currnecy',
#ComponentSum.[Accumulated Depreciation] as 'Accumulated Depreciation' ,
#ComponentSum.[Accumulated Depreciation Currency] as 'Accumulated Depreciation Currency',
#ComponentCollection.EndBookValue_Amount as 'End Book Value',
#ComponentCollection.EndBookValue_Currency as 'End Book Value Currency',
Assets.CurrencyCode as 'Currency'
FROM #ComponentCollection
JOIN #ComponentSum on #ComponentCollection.AssetId = #ComponentSum.AssetId
JOIN Assets on #ComponentCollection.AssetId = Assets.Id
JOIN LegalEntities on Assets.LegalEntityId = LegalEntities.Id
LEFT JOIN LeaseAssets on #ComponentCollection.AssetId = LeaseAssets.AssetId
LEFT JOIN LeaseFinances on LeaseAssets.LeaseFinanceId = LeaseFinances.Id
LEFT JOIN contracts on LeaseFinances.ContractId = contracts.Id
WHERE (@SequenceNumber IS NULL OR contracts.Id IS NULL or contracts.SequenceNumber = @SequenceNumber) and
(@LegalEntityName IS NULL OR LegalEntities.Name in (select value from String_split(@LegalEntityName,','))) and
(LeaseFinances.Id IS NULL OR LeaseFinances.IsCurrent = 1)
drop table #ComponentCollection
drop table #ComponentSum
drop table #MaximumComponent
drop table #MaximumComponentValues
drop table #MinimumComponent
drop table #MinimumComponentValues
end
else
begin
SELECT Id,SourceModule,AssetId,ROW_NUMBER() over (Partition by AssetId order by Id desc) as 'Maximum' INTO #Maximum
FROM AssetValueHistories
WHERE incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
SELECT Id,SourceModule,AssetId,ROW_NUMBER() over (Partition by AssetId order by Id) as 'Minimum' INTO #Minimum
FROM AssetValueHistories
WHERE incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
SELECT AssetValueHistories.Id,
AssetValueHistories.AssetId ,
AssetValueHistories.Value_Amount,
AssetValueHistories.Value_Currency,
AssetValueHistories.EndBookValue_Amount,
AssetValueHistories.EndBookValue_Currency
INTO #MaximumValues
FROM AssetValueHistories
JOIN #Maximum
on AssetValueHistories.Id = #Maximum.Id
Where #Maximum.Maximum = 1 and AssetValueHistories.IsLessorOwned=1
SELECT AssetValueHistories.Id,
AssetValueHistories.AssetId ,
AssetValueHistories.Cost_Amount ,
AssetValueHistories.Cost_Currency
INTO #MinimumValues
FROM AssetValueHistories
JOIN #Minimum
on AssetValueHistories.Id = #Minimum.Id
Where #Minimum.Minimum = 1 and AssetValueHistories.IsLessorOwned=1
SELECT #MaximumValues.Id,
#MaximumValues.AssetId ,
#MaximumValues.Value_Amount,
#MaximumValues.Value_Currency,
#MinimumValues.Cost_Amount,
#MinimumValues.Cost_Currency,
#MaximumValues.EndBookValue_Amount,
#MaximumValues.EndBookValue_Currency
INTO #collection
FROM #MaximumValues
JOIN #MinimumValues
on #MaximumValues.AssetId = #MinimumValues.AssetId
SELECT AssetValueHistories.AssetId ,
sum(AssetValueHistories.Value_Amount) as 'Accumulated Depreciation',
AssetValueHistories.Value_Currency as 'Accumulated Depreciation Currency'
INTO #sum
FROM AssetValueHistories
WHERE incomedate <= @IncomeDate and ((@SequenceNumber is not null and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation')) or (@SequenceNumber IS NULL and AssetValueHistories.SourceModule in ('FixedTermDepreciation','OTPDepreciation','InventoryBookDepreciation')))
and AssetValueHistories.IsLessorOwned=1
GROUP BY AssetValueHistories.AssetId, AssetValueHistories.Value_Currency
SELECT
contracts.SequenceNumber,
#Collection.AssetId as 'Asset Id' ,
#collection.Cost_Amount as 'Initial Cost',
#collection.Cost_Currency as 'Initial Cost Currency',
#Collection.Value_Amount as 'Book Depriciation' ,
#Collection.Value_Currency as 'Book Depriciation Currnecy',
#sum.[Accumulated Depreciation] as 'Accumulated Depreciation' ,
#sum.[Accumulated Depreciation Currency] as 'Accumulated Depreciation Currency',
#collection.EndBookValue_Amount as 'End Book Value',
#collection.EndBookValue_Currency as 'End Book Value Currency',
Assets.CurrencyCode as 'Currency'
FROM #Collection
JOIN #sum on #Collection.AssetId = #sum.AssetId
JOIN Assets on #collection.AssetId = Assets.Id
JOIN LegalEntities on Assets.LegalEntityId = LegalEntities.Id
LEFT JOIN LeaseAssets on #collection.AssetId = LeaseAssets.AssetId
LEFT JOIN LeaseFinances on LeaseAssets.LeaseFinanceId = LeaseFinances.Id
LEFT JOIN contracts on LeaseFinances.ContractId = contracts.Id
WHERE (@SequenceNumber IS NULL OR contracts.Id IS NULL or contracts.SequenceNumber = @SequenceNumber) and
(@LegalEntityName IS NULL OR LegalEntities.Name in (select value from String_split(@LegalEntityName,','))) and
(LeaseFinances.Id IS NULL OR LeaseFinances.IsCurrent = 1)
DROP TABLE #Maximum
DROP TABLE #MaximumValues
DROP TABLE #Minimum
DROP TABLE #MinimumValues
DROP TABLE #sum
DROP TABLE #Collection
end
End

GO
