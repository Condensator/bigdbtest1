SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROC [dbo].[GetAssetSaleGLEntryItemsMatchingGL]
(
@AssetSaleInfo AssetSaleInfo READONLY,
@PayOffStatus NVARCHAR(30),
@SourceModulePayableInvoice NVARCHAR(30),
@SourceModuleAssetValueAdjustment NVARCHAR(30),
@SourceModulePayoff NVARCHAR(30),
@SourceModulePaydown NVARCHAR(30),
@SourceModuleAssetImpairment NVARCHAR(30),
@SourceModuleNBVImpairments NVARCHAR(30),
@SourceModuleInventoryBookDepreciation NVARCHAR(30),
@SourceModuleFixedTermDepreciation NVARCHAR(30),
@SourceModuleOTPDepreciation NVARCHAR(30),
@GLEntryItemInventory NVARCHAR(60),
@GLEntryItemAccumulatedAssetImpairment NVARCHAR(60),
@GLEntryItemAccumulatedAssetDepreciation NVARCHAR(60)
)
AS
Begin
SET NOCOUNT ON
Create Table #Results (AssetId int, MatchingGLTemplateId int, GLEntryItem Nvarchar(100), AssetCategory Nvarchar(100), IsForInventoryBookDep BIT, RecordNumber INT);
DECLARE @SourceModule NVARCHAR(Max);
DECLARE @SourceModuleId INT;
DECLARE @Id INT;
DECLARE @AVHRecordsCount INT;
DECLARE @LatestAVHClearanceId BIGINT;
DECLARE @RecCount INT;
DECLARE Assets_Cursor CURSOR FAST_FORWARD FOR  Select AssetId from @AssetSaleInfo;
OPEN Assets_Cursor
FETCH NEXT FROM Assets_Cursor INTO @Id
WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @FreshAsset_Inventory_AssetId INT = 0;
;With CTE_FreshAsset_Inventory As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON  assetdeatils.AssetId =AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModuleAssetValueAdjustment,@SourceModulePayableInvoice)
and assetdeatils.IsTransferAsset = 0
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId,@FreshAsset_Inventory_AssetId = AssetId from CTE_FreshAsset_Inventory;
if (@SourceModule = @SourceModulePayableInvoice)
begin
Insert into #Results
Select @Id, PayableCodes.GLTemplateId As MatchingGLTemplateId, @GLEntryItemInventory As GlEntryItem, 'Fresh Asset' As AssetCategory, 0 As IsForInventoryBookDep, 1 As RecordNumber
from PayableCodes
join PayableInvoices On PayableInvoices.AssetCostPayableCodeId = PayableCodes.Id
join GLTemplates on GLTemplates.Id = PayableCodes.GLTemplateId
join GLTransactionTypes on GLTransactionTypes.Id = GLTemplates.GLTransactionTypeId
Where PayableInvoices.Id = @SourceModuleId AND  GLTransactionTypes.Name = 'AssetPurchaseAP'
Set @SourceModule = null;
end
else if (@SourceModule = @SourceModuleAssetValueAdjustment)
begin
Insert into #Results
Select @Id, AssetsValueStatusChangeDetails.GLTemplateId As MatchingGLTemplateId, @GLEntryItemInventory As GlEntryItem, 'Fresh Asset' As AssetCategory, 0 As IsForInventoryBookDep, 2 As RecordNumber
from AssetsValueStatusChanges
join AssetsValueStatusChangeDetails On AssetsValueStatusChangeDetails.AssetsValueStatusChangeId = AssetsValueStatusChanges.Id
Where AssetsValueStatusChanges.Id = @SourceModuleId and AssetsValueStatusChangeDetails.AssetId = @Id
Set @SourceModule = null;
end
/**/
;With CTE_FreshAsset_Impairment As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo  assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModuleAssetImpairment)
and assetdeatils.IsTransferAsset = 0
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_FreshAsset_Impairment;
if (@SourceModule = @SourceModuleAssetImpairment)
begin
Insert into #Results
Select @Id, AssetsValueStatusChangeDetails.GLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetImpairment As GlEntryItem, 'Fresh Asset' As AssetCategory, 0 As IsForInventoryBookDep, 3 As RecordNumber
from AssetsValueStatusChanges
join AssetsValueStatusChangeDetails On AssetsValueStatusChangeDetails.AssetsValueStatusChangeId = AssetsValueStatusChanges.Id
Where AssetsValueStatusChanges.Id = @SourceModuleId and AssetsValueStatusChangeDetails.AssetId = @Id
Set @SourceModule = null;
end
/**/
;With CTE_FreshAsset_BookDepreciation As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModuleInventoryBookDepreciation)
and assetdeatils.IsTransferAsset = 0
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_FreshAsset_BookDepreciation;
if (@SourceModule = @SourceModuleInventoryBookDepreciation)
begin
Insert into #Results
Select @Id, BookDepreciations.GLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetDepreciation As GlEntryItem, 'Fresh Asset' As AssetCategory, 1 As IsForInventoryBookDep, 4 As RecordNumber
from BookDepreciations
Where BookDepreciations.Id = @SourceModuleId and BookDepreciations.AssetId = @Id
Set @SourceModule = null;
end
/*Paid*/
DECLARE @RecordCnt INT = 0;
;With CTE_PaidOffAsset_Inventory As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModuleAssetValueAdjustment,@SourceModulePayoff)
and assetdeatils.IsTransferAsset = 1
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId, @RecordCnt = AssetId from CTE_PaidOffAsset_Inventory
begin
Insert into #Results
Select @Id, Payoffs.PayoffGLTemplateId As MatchingGLTemplateId, @GLEntryItemInventory As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 0 As IsForInventoryBookDep, 6 As RecordNumber
from Payoffs
join PayoffAssets on PayoffAssets.PayoffId = Payoffs.Id
join LeaseAssets on LeaseAssets.Id = PayoffAssets.LeaseAssetId
join Assets on LeaseAssets.AssetId=Assets.Id
Join Contracts on Assets.PreviousSequenceNumber=Contracts.SequenceNumber
join LeaseFinances on Payoffs.LeaseFinanceId=LeaseFinances.Id and Contracts.Id=	LeaseFinances.ContractId
Where LeaseAssets.AssetId = @Id and Payoffs.Status= @PayOffStatus and PayoffAssets.IsActive = 1
Set @SourceModule = null;
end
if (@RecordCnt = 0 or @RecordCnt is null)
begin
;With CTE_PaidOffAsset_Inventory_Except As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1  and IsLessorOwned = 1
and SourceModule IN (@SourceModuleAssetValueAdjustment,@SourceModulePayableInvoice)
and assetdeatils.IsTransferAsset = 1
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_PaidOffAsset_Inventory_Except;
if (@SourceModule = @SourceModulePayableInvoice and @Id != @FreshAsset_Inventory_AssetId) -- tricky check
begin
Insert into #Results
Select @Id, Payoffs.PayoffGLTemplateId As MatchingGLTemplateId, @GLEntryItemInventory As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 0 As IsForInventoryBookDep, 7 As RecordNumber
from Payoffs
join PayoffAssets on PayoffAssets.PayoffId = Payoffs.Id
join LeaseAssets on LeaseAssets.Id = PayoffAssets.LeaseAssetId
join Assets on LeaseAssets.AssetId=Assets.Id
Join Contracts on Assets.PreviousSequenceNumber=Contracts.SequenceNumber
join LeaseFinances on Payoffs.LeaseFinanceId=LeaseFinances.Id and Contracts.Id=	LeaseFinances.ContractId
Where  LeaseAssets.AssetId = @Id and Payoffs.Status=@PayOffStatus and PayoffAssets.IsActive = 1
Set @SourceModule = null;
end
end -- RecordCnt end
/**/

select @LatestAVHClearanceId = (select top 1 AssetValueHistories.Id
								from AssetValueHistories
								Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
								where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1 and IsCleared =1 and assetdeatils.IsTransferAsset = 1
								order by AssetValueHistories.IncomeDate DESC, AssetValueHistories.Id DESC)

Select @AVHRecordsCount = Count(AssetValueHistories.Id)
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1 and AssetValueHistories.Id > @LatestAVHClearanceId
and SourceModule IN (@SourceModuleFixedTermDepreciation, @SourceModuleOTPDepreciation)

if (@AVHRecordsCount > 0)
begin
Insert into #Results
Select @Id, Payoffs.PayoffGLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetDepreciation As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 0 As IsForInventoryBookDep, 8 As RecordNumber
from Payoffs
join PayoffAssets on PayoffAssets.PayoffId = Payoffs.Id
join LeaseAssets on LeaseAssets.Id = PayoffAssets.LeaseAssetId
join Assets on LeaseAssets.AssetId=Assets.Id
Join Contracts on Assets.PreviousSequenceNumber=Contracts.SequenceNumber
join LeaseFinances on Payoffs.LeaseFinanceId=LeaseFinances.Id and Contracts.Id=	LeaseFinances.ContractId
Where LeaseAssets.AssetId = @Id and Payoffs.Status=@PayOffStatus and PayoffAssets.IsActive = 1
end

;With CTE_PaidOffAsset_InventoryDep As
(
select top 1 AssetValueHistories.AssetId, SourceModule, SourceModuleId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1 and AssetValueHistories.Id > @LatestAVHClearanceId
and SourceModule IN (@SourceModuleInventoryBookDepreciation)
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_PaidOffAsset_InventoryDep
if (@SourceModule = @SourceModuleInventoryBookDepreciation)
begin
Insert into #Results
Select @Id, BookDepreciations.GLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetDepreciation As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 1 As IsForInventoryBookDep, 9 As RecordNumber
from BookDepreciations
Where BookDepreciations.Id = @SourceModuleId and BookDepreciations.AssetId = @Id
Set @SourceModule = null;
end

/**/
;With CTE_PaidOffAsset_AssetImpairement As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModulePayoff, @SourceModuleAssetValueAdjustment,@SourceModuleAssetImpairment,@SourceModuleNBVImpairments)
and assetdeatils.IsTransferAsset = 1
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_PaidOffAsset_AssetImpairement
if (@SourceModule = @SourceModuleAssetValueAdjustment)
begin
Insert into #Results
Select @Id, AssetsValueStatusChangeDetails.GLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetImpairment As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 0 As IsForInventoryBookDep, 10 As RecordNumber
from AssetsValueStatusChanges
join AssetsValueStatusChangeDetails On AssetsValueStatusChangeDetails.AssetsValueStatusChangeId = AssetsValueStatusChanges.Id
Where AssetsValueStatusChanges.Id = @SourceModuleId and AssetsValueStatusChangeDetails.AssetId = @Id
Set @SourceModule = null;
end
else if (@SourceModule = @SourceModuleNBVImpairments or @SourceModule = @SourceModulePayoff or @SourceModule = @SourceModuleAssetImpairment )
begin
Insert into #Results
Select @Id, Payoffs.PayoffGLTemplateId As MatchingGLTemplateId, @GLEntryItemAccumulatedAssetImpairment As GlEntryItem, 'Paid-Off Asset' As AssetCategory, 0 As IsForInventoryBookDep, 11 As RecordNumber
from Payoffs
join PayoffAssets on PayoffAssets.PayoffId = Payoffs.Id
join LeaseAssets on LeaseAssets.Id = PayoffAssets.LeaseAssetId
join Assets on LeaseAssets.AssetId=Assets.Id
Join Contracts on Assets.PreviousSequenceNumber=Contracts.SequenceNumber
join LeaseFinances on Payoffs.LeaseFinanceId=LeaseFinances.Id and Contracts.Id=	LeaseFinances.ContractId
Where  LeaseAssets.AssetId = @Id and Payoffs.Status=@PayOffStatus and PayoffAssets.IsActive = 1
order by Payoffs.Id desc
Set @SourceModule = null;
end
/**/
;With CTE_Paydown_Inventory As
(
select top 1 AssetValueHistories.AssetId,SourceModule,SourceModuleId,AssetValueHistories.Id As AVHId
from AssetValueHistories
Join @AssetSaleInfo assetdeatils ON assetdeatils.AssetId = AssetValueHistories.AssetId
where assetdeatils.AssetId = @Id and IsAccounted = 1 and IsLessorOwned = 1
and SourceModule IN (@SourceModulePaydown)
and assetdeatils.IsTransferAsset = 1
order by AssetValueHistories.Id DESC
)
select @SourceModule = SourceModule, @SourceModuleId = SourceModuleId, @Id = AssetId from CTE_Paydown_Inventory
if (@SourceModule = @SourceModulePaydown)
begin
Insert into #Results
Select @Id, LoanPaydowns.PaydownGLTemplateId As MatchingGLTemplateId, @GLEntryItemInventory As GlEntryItem, 'Paid-Down Asset' As AssetCategory, 0 As IsForInventoryBookDep, 12 As RecordNumber
from LoanPaydowns
join LoanPaydownAssetDetails On LoanPaydownAssetDetails.LoanPaydownId = LoanPaydowns.Id
Where LoanPaydowns.Id = @SourceModuleId and LoanPaydownAssetDetails.AssetId = @Id
Set @SourceModule = null;
end
SET @SourceModuleId = null; SET @SourceModule = null; SET @Id = null;
FETCH NEXT FROM Assets_Cursor INTO @Id;
END
CLOSE Assets_Cursor;
DEALLOCATE Assets_Cursor;
select * from #Results order by AssetId
drop table #Results
end

GO
