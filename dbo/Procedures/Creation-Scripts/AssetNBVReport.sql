SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create proc [dbo].[AssetNBVReport]
(
@LegalEntityName NVarchar(100) = NULL,
@SequenceNumber Nvarchar(80) = NULL,
@CustomerId Nvarchar(100) = NULL,
@AsOfDate AS Date = NULL,
@LegalEntityIds NVarchar(max) = NULL
)
As
--Declare @SequenceNumber Nvarchar(100) = 'ab'
--Declare @LegalEntityIds  NVarchar(max) = 'cv'
--Declare @CustomerId BIGINT = 1
--Declare @AsOfDate AS Date = getdate()
Begin
SET NOCOUNT ON;
DECLARE @FilterConditions nvarchar(max)
DECLARE @sql nvarchar(max)
Set @FilterConditions = ''
IF @CustomerId IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'Parties.PartyNumber = @CustomerId'
END
IF  @SequenceNumber IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'Contracts.SequenceNumber = @SequenceNumber'
END
IF  @LegalEntityIds IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'LegalEntities.Id in('+ 'SELECT value
FROM STRING_SPLIT(@LegalEntityIds,'',''))'
END
IF  @AsOfDate IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  'AssetValueHistories.IncomeDate <= @AsOfDate'
END

SET @FilterConditions = @FilterConditions + (CASE WHEN LEN(@FilterConditions) = 0 THEN ' WHERE ' ELSE ' AND ' END)
SET @FilterConditions = @FilterConditions +  '(Contracts.BackgroundProcessingPending IS NULL OR Contracts.BackgroundProcessingPending = 0)'

SET @sql='
Create Table #ResultSet
(
LegalEntityName NVarchar(200),
PartyNumber NVarchar(80),
PartyName NVarchar(500),
Status NVarchar(34),
SequenceNumber NVarchar(80),
AssetId BigInt,
CustomerId BigInt,
AssetAlias NVarchar(200),
PurchaseCost Decimal(18,2),
PurchaseCostCurrency nvarchar(3),
BeginNBV Decimal(18,2),
BeginNBVCurrency nvarchar(3),
NetBookValue Decimal(18,2),
NetBookValueCurrency nvarchar(3),
ImpairmentAmount Decimal(18,2),
ImpairmentAmountCurrency nvarchar(3),
DepreciationAmount Decimal(18,2),
DepreciationAmountCurrency nvarchar(3),
CapitalLeasePrincipalReduction Decimal(18,2),
CapitalLeasePrincipalReductionCurrency nvarchar(3)
)

Select AssetValueHistories.AssetId into #SelectedAssets From AssetValueHistories
	Inner Join Assets On Assets.Id = AssetValueHistories.AssetId
	Inner Join LegalEntities On LegalEntities.Id = Assets.LegalEntityId
	Left Join Parties On Parties.Id = Assets.CustomerId
	Left Join
	(
		Select LeaseAssets.AssetId, Contracts.SequenceNumber, Contracts.BackgroundProcessingPending From LeaseAssets
		Join LeaseFinances On LeaseAssets.LeaseFinanceId = LeaseFinances.Id
		Join Contracts On LeaseFinances.ContractId = Contracts.Id
		Where LeaseAssets.IsActive = 1 And LeaseFinances.IsCurrent = 1
	) As Contracts On Contracts.AssetId = Assets.Id
	FILTERCONDITIONS
	Group By AssetValueHistories.AssetId;

	SELECT AVH.AssetId, IncomeDate, AVH.Id,AVH.IsLeaseComponent, ROW_NUMBER() OVER(PARTITION BY AVH.IsLeaseComponent, AVH.AssetId ORDER BY AVH.IncomeDate DESC, AVH.Id DESC) [RowNumber]
	INTO #MaxAVH FROM #SelectedAssets SA
	JOIN AssetValueHistories AVH ON SA.AssetId = AVH.AssetId
	WHERE AVH.IsCleared = 1 And SourceModule <> ''Payoff'' And AVH.IsSchedule = 1
	And ((SourceModule = ''AssetValueAdjustment'' And AVH.IncomeDate <= @AsOfDate) Or AVH.IncomeDate < @AsOfDate)


Select #SelectedAssets.AssetId into #RemainingAssets From #SelectedAssets
	Left Join #MaxAVH On #SelectedAssets.AssetId = #MaxAVH.AssetId AND #MaxAVH.RowNumber = 1
	Where #MaxAVH.AssetId IS NULL
	
	Select AssetValueHistories.Id,
ROW_NUMBER() OVER(PARTITION BY AssetValueHistories.AssetId,AssetValueHistories.IsLeaseComponent  ORDER BY AssetValueHistories.IncomeDate DESC, AssetValueHistories.Id DESC) [Row_Numb]
Into #RecentHistory From AssetValueHistories Inner Join #SelectedAssets On #SelectedAssets.AssetId = AssetValueHistories.AssetId
Where AssetValueHistories.IncomeDate <= @AsOfDate And AssetValueHistories.IsSchedule = 1 And AssetValueHistories.IsLessorOwned = 1



Insert Into #ResultSet
Select
LegalEntities.Name,
NULL,
NULL,
Assets.Status,
NULL,
#SelectedAssets.AssetId,
Assets.CustomerId,
Assets.Alias,
0,
Assets.CurrencyCode,
0,
Assets.CurrencyCode,
0,
Assets.CurrencyCode,
0,
Assets.CurrencyCode,
0,
Assets.CurrencyCode,
0,
Assets.CurrencyCode

From Assets
Inner Join #SelectedAssets On #SelectedAssets.AssetId = Assets.Id
Inner Join LegalEntities on LegalEntities.Id = Assets.LegalEntityId

Update #ResultSet Set PartyNumber = Parties.PartyNumber, PartyName = Parties.PartyName From #ResultSet
Inner Join Parties on Parties.Id = #ResultSet.CustomerId

Update #ResultSet Set SequenceNumber = Contracts.SequenceNumber From #ResultSet
Inner Join LeaseAssets On LeaseAssets.AssetId = #ResultSet.AssetId And LeaseAssets.IsActive = 1
Inner Join LeaseFinances on LeaseFinances.Id = LeaseAssets.LeaseFinanceId And LeaseFinances.IsCurrent = 1
Inner Join Contracts on Contracts.Id = LeaseFinances.ContractId

;With CTE_AssetImpairment As
(
	Select 0-SUM(Value_Amount) [ImpairmentAmount],Value_Currency [ImpairmentAmountCurrency],  AssetValueHistories.AssetId From AssetValueHistories
	Inner Join #MaxAVH On #MaxAVH.AssetId = AssetValueHistories.AssetId  And #MaxAVH.RowNumber = 1
	Where AssetValueHistories.SourceModule IN (''AssetValueAdjustment'', ''AssetImpairment'', ''NBVImpairments'')
	And AssetValueHistories.IsSchedule = 1 And AssetValueHistories.IncomeDate <= @AsOfDate
	And ((AssetValueHistories.IncomeDate = #MaxAVH.IncomeDate And AssetValueHistories.Id > #MaxAVH.Id) 
		Or AssetValueHistories.IncomeDate > #MaxAVH.IncomeDate) And AssetValueHistories.IsLessorOwned = 1 AND AssetValueHistories.IsLeaseComponent = #MaxAVH.IsLeaseComponent
	Group By AssetValueHistories.AssetId,Value_Currency

	UNION ALL

    Select 0-SUM(Value_Amount) [ImpairmentAmount],Value_Currency [ImpairmentAmountCurrency], AssetValueHistories.AssetId From AssetValueHistories
	Inner join #RemainingAssets ON AssetValueHistories.AssetId = #RemainingAssets.AssetId
	Where AssetValueHistories.SourceModule IN (''AssetValueAdjustment'', ''AssetImpairment'', ''NBVImpairments'')
	And AssetValueHistories.IsSchedule = 1 And AssetValueHistories.IncomeDate <= @AsOfDate
	And AssetValueHistories.IsLessorOwned = 1
	Group By AssetValueHistories.AssetId,Value_Currency
)
Update #ResultSet  Set ImpairmentAmount = CTE_AssetImpairment.ImpairmentAmount,ImpairmentAmountCurrency = CTE_AssetImpairment.ImpairmentAmountCurrency  From #ResultSet
Inner Join CTE_AssetImpairment on CTE_AssetImpairment.AssetId = #ResultSet.AssetId

;With CTE_AccumulatedDepreciation As
(
	Select 0-SUM(Value_Amount) [DepreciationAmount], Value_Currency [DepreciationAmountCurrency], AssetValueHistories.AssetId From AssetValueHistories
	Inner Join #MaxAVH On #MaxAVH.AssetId = AssetValueHistories.AssetId and #MaxAVH.RowNumber = 1
	Where AssetValueHistories.SourceModule IN (''FixedTermDepreciation'', ''OTPDepreciation'', ''InventoryBookDepreciation'', ''ResidualReclass'', ''ResidualRecapture'')
	And AssetValueHistories.IsSchedule = 1 And AssetValueHistories.IncomeDate <= @AsOfDate
		And ((AssetValueHistories.IncomeDate = #MaxAVH.IncomeDate And AssetValueHistories.Id > #MaxAVH.Id) 
		Or AssetValueHistories.IncomeDate > #MaxAVH.IncomeDate) And AssetValueHistories.IsLessorOwned = 1
		And  AssetValueHistories.IsLeaseComponent = #MaxAVH.IsLeaseComponent
	Group By AssetValueHistories.AssetId, Value_Currency

	UNION ALL

	Select 0-SUM(Value_Amount) [DepreciationAmount], Value_Currency [DepreciationAmountCurrency], AssetValueHistories.AssetId From AssetValueHistories
	Inner join #RemainingAssets ON AssetValueHistories.AssetId = #RemainingAssets.AssetId
	Where AssetValueHistories.SourceModule IN (''FixedTermDepreciation'', ''OTPDepreciation'', ''InventoryBookDepreciation'', ''ResidualReclass'', ''ResidualRecapture'')
	And AssetValueHistories.IsSchedule = 1 And AssetValueHistories.IncomeDate <= @AsOfDate
	And AssetValueHistories.IsLessorOwned = 1
	Group By AssetValueHistories.AssetId, Value_Currency
)
Update #ResultSet  Set DepreciationAmount = CTE_AccumulatedDepreciation.DepreciationAmount,DepreciationAmountCurrency = CTE_AccumulatedDepreciation.DepreciationAmountCurrency  From #ResultSet
Inner Join CTE_AccumulatedDepreciation on CTE_AccumulatedDepreciation.AssetId = #ResultSet.AssetId

;With CTE_PurchaseCostAndNBV As
(	
	Select SUM(Cost_Amount) [PurchaseCost], Cost_Currency [PurchaseCostCurrency], SUM(EndBookValue_Amount) [NetBookValue],EndBookValue_Currency [NetBookValueCurrency],  AssetValueHistories.AssetId 
	From #RecentHistory Inner Join AssetValueHistories On AssetValueHistories.Id = #RecentHistory.Id And #RecentHistory.Row_Numb = 1 
	Group by AssetId,Cost_Currency,EndBookValue_Currency

)

Update #ResultSet  Set PurchaseCost = CTE_PurchaseCostAndNBV.PurchaseCost,PurchaseCostCurrency =  CTE_PurchaseCostAndNBV.PurchaseCostCurrency, NetBookValue = CTE_PurchaseCostAndNBV.NetBookValue, NetBookValueCurrency = CTE_PurchaseCostAndNBV.NetBookValueCurrency From #ResultSet
Inner Join CTE_PurchaseCostAndNBV on CTE_PurchaseCostAndNBV.AssetId = #ResultSet.AssetId


;With CTE_CapitalLeasePrincipalReduction As
(
	Select 0 - SUM(Value_Amount) [CapitalLeasePrincipalReduction], AssetValueHistories.AssetId From AssetValueHistories  
	Inner Join #MaxAVH On #MaxAVH.AssetId = AssetValueHistories.AssetId and #MaxAVH.RowNumber = 1
	Where AssetValueHistories.SourceModule IN (''Payoff'') And AssetValueHistories.IsSchedule = 1 
	And AssetValueHistories.IncomeDate <= @AsOfDate 
	And ((AssetValueHistories.IncomeDate = #MaxAVH.IncomeDate And AssetValueHistories.Id >= #MaxAVH.Id) 
		Or AssetValueHistories.IncomeDate > #MaxAVH.IncomeDate)
		AND AssetValueHistories.IsLeaseComponent = #MaxAVH.IsLeaseComponent
	Group By AssetValueHistories.AssetId

	
)
Update #ResultSet Set CapitalLeasePrincipalReduction = CTE_CapitalLeasePrincipalReduction.CapitalLeasePrincipalReduction From #ResultSet   
Inner Join CTE_CapitalLeasePrincipalReduction on CTE_CapitalLeasePrincipalReduction.AssetId = #ResultSet.AssetId

Update #ResultSet 
Set BeginNBV = NetBookValue + CapitalLeasePrincipalReduction + DepreciationAmount + ImpairmentAmount,
	CapitalLeasePrincipalReduction = ABS(CapitalLeasePrincipalReduction),
	DepreciationAmount = ABS(DepreciationAmount),
	ImpairmentAmount = ABS(ImpairmentAmount)

Select * From #ResultSet Order by LegalEntityName, CustomerId, PartyName
Drop Table #ResultSet
Drop Table #SelectedAssets
Drop Table #MaxAVH
Drop Table #RemainingAssets
Drop Table #RecentHistory
'
IF @FilterConditions IS NOT NULL
SET @sql = REPLACE(@sql, 'FILTERCONDITIONS', @FilterConditions )
ELSE
SET @sql = REPLACE(@sql, 'FILTERCONDITIONS', '' )
END
EXEC sp_executesql @sql, N'
@LegalEntityName nvarchar(100),
@SequenceNumber Nvarchar(100),
@CustomerId nvarchar(100),
@AsOfDate Date,
@LegalEntityIds nvarchar(max)',
@LegalEntityName,
@SequenceNumber,
@CustomerId,
@AsOfDate,
@LegalEntityIds

GO
