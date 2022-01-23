SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetBookDepreciationDetailsForAsset]
(   
    @AssetIds AssetIdWithBookDepreciation READONLY,
	@CommencementDate DATETIME
)

AS 
BEGIN
SET NOCOUNT ON
	
CREATE TABLE #AssetDetails
(
	AssetId BIGINT INDEX  IX_AssetId,
	BookDepExists BIT,
	BookDepId BIGINT,
	BookDepLatestDate DATETIME,
	PreviousBookDepEndDate DATETIME,
	BookDepStartDate DATETIME,
	PerDayDepreciationFactor DECIMAL(18,8),
	PreviousBookDepTerminatedDate DATETIME,
	CostBasis DECIMAL(16,2),
	RemainingEconomicLife INT,
	EndValue DECIMAL(16,2),
	IncomeDate DATETIME,
	SourceModule nvarchar(25),
	IsLeaseComponent BIT
)
INSERT INTO #AssetDetails
	select BookDepreciations.AssetId, 
	case when BookDepreciations.Id is not null THEN 1 else 0 end as 'BookDepExists',
	BookDepreciations.Id as 'BookDepId',BookDepreciations.LastAmortRunDate as 'BookDepLatestDate',
	BookDepreciations.EndDate as 'PreviousBookDepEndDate',
	BookDepreciations.BeginDate as'BookDepStartDate',
	BookDepreciations.PerDayDepreciationFactor as 'PerDayDepreciationFactor',
	BookDepreciations.TerminatedDate as'PreviousBookDepTerminatedDate',
	BookDepreciations.CostBasis_Amount 'CostBasis',
	BookDepreciations.RemainingLifeInMonths as 'RemainingEconomicLife',
	AssetValueHistories.EndBookValue_Amount 'EndValue',
	AssetValueHistories.IncomeDate 'IncomeDate',
	AssetValueHistories.SourceModule 'SourceModule',
	BookDepreciations.IsLeaseComponent
from
	(
	select BookDepreciations.AssetId,MAX(BookDepreciations.BeginDate) MaxBeginDate from @AssetIds AssetIds
	join BookDepreciations on AssetIds.AssetId = BookDepreciations.AssetId
	where BookDepreciations.ContractId is null  AND BookDepreciations.IsActive=1
	AND BookDepreciations.BeginDate < @CommencementDate
	group by BookDepreciations.AssetId
	) t1
join BookDepreciations on t1.AssetId=BookDepreciations.AssetId and t1.MaxBeginDate=BookDepreciations.BeginDate AND BookDepreciations.IsActive=1
left join (select AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent ,MAX(AssetValueHistories.IncomeDate) MaxIncomeDate,Max(AssetValueHistories.Id) as MaxAVHId from AssetValueHistories join @AssetIds AssetIds on AssetValueHistories.AssetId= AssetIds.AssetId
where (AssetValueHistories.SourceModule='InventoryBookDepreciation')
and AssetValueHistories.IsSchedule=1 
AND AssetValueHistories.IsLessorOwned = 1
and AssetValueHistories.IncomeDate < @CommencementDate
group by AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent
 ) t2 on BookDepreciations.AssetId =t2.AssetId 
	AND BookDepreciations.IsLeaseComponent = t2.IsLeaseComponent
 left join AssetValueHistories on t2.AssetId= AssetValueHistories.AssetId and t2.MaxIncomeDate=AssetValueHistories.IncomeDate and AssetValueHistories.Id = t2.MaxAVHId AND  AssetValueHistories.IsSchedule=1  AND AssetValueHistories.SourceModuleId = BookDepreciations.Id

 SELECT * FROM #AssetDetails

 DROP TABLE #AssetDetails

END

GO
