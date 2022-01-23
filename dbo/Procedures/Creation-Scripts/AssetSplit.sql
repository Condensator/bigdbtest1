SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[AssetSplit]
(
@SplitByType NVARCHAR(20)
, @AssetId BIGINT
, @UserId INT
, @Currency NVARCHAR(3)
, @AssetSplitId BIGINT
, @AssetDetail AssetDetails READONLY
, @Time DATETIMEOFFSET
, @JobInstanceId BigInt
, @IsBlendedRecoveryMethod BIT
)AS
--DECLARE @AssetId BIGINT
--DECLARE @UserId INT
--DECLARE @SplitByType NVARCHAR(20)
--DECLARE @Currency NVARCHAR(3)
--DECLARE @TEST NVARCHAR(3)
--DECLARE @AssetSplitId BIGINT
--SET @AssetId = 189165737
--SET @UserId = 123
--SET @SplitByType = 'AssetSplit'
--SET @Currency = 'USD'
--SET @TEST = '123'
--SET @AssetSplitId = 123
--BEGIN TRAN @TEST
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN -- Declaration
DECLARE @JobInstanceIdInString varchar(30) = CAST(@JobInstanceId as varchar(30)) /*used in dynamic queries building; instead of type casting in all places we use this variable*/
Create Table #SelectedAssets (SelectedAssetId BIGINT, FinancialType NVARCHAR(30))
Create Table #NewlyCreatedAssetIds (NewAssetId BIGINT)
Create Table #DuplicateAssets (RowNum BIGINT IDENTITY(1,1), DuplicateAssetId BIGINT, FeatureAsset Bit, Prorate Decimal(18,10), FinancialType NVARCHAR(30), Quantity INT,IsLastAsset TINYINT)
Create Table #SplitedAssets (NewAssetID BIGINT, OldAssetID BIGINT, IsLastAsset TINYINT, Prorate Decimal(18,10), FeatureAsset Bit ,RowNum BIGINT , FinancialType NVARCHAR(30) , Quantity INT , RowNumByFinancialType INT, ReaccrualNBV Decimal(16,2));
Create Table #PayableInvoiceAssetsTemp (RowNum INT, OldId BigInt, NewId BigInt, OldAssetId BigInt, NewAssetId BigInt , PayableInvoiceId BIGINT, FeatureAsset Bit)
Create Table #PayableInvoiceTemp(Id BIGINT)
Create Table #PayableInvoiceCountTemp(Id BIGINT, AssetCount int)
Create Table #PayableInvoiceDepositAssetsTemp (RowNum INT, OldId BigInt, NewId BigInt , NewAssetId BigInt);
Create Table #PayableInvoiceNegativeTakedownAssetsTemp(OldId BigInt, NewId BIGINT, OldPayableInvoiceDepositAssetId BIGINT, OldTakeDownAssetId BIGINT, NewAssetId BigInt);
Create Table #AssetFeaturesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
Create Table #AssetParameter (RowNum BIGINT IDENTITY(1,1), AssetFeatureId INT , AssetId INT , NewAmount Decimal(18,10) , Alias NVARCHAR(MAX))
Create Table #PayableInvoiceOtherCostsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
Create Table #PayableInvoiceOtherCostDetailsTemp (RowNum INT,OldId BIGINT , NewId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AllocationMethodDetails(OtherCostId BIGINT)
Create Table #AssetLocationsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create Table #AssetSerialNumbersTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetMetersTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetHistoriesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
create Table #AssetHistoriesMaxTemp (Id BIGINT, AssetId BIGINT)
Create Table #AssetValueHistoriesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
Create Table #AssetValueHistoryDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetsLocationChangeDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetsValueStatusChangeDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #VertexBilledRentalReceivablesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #MaturityMonitorFMVAssetDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LoanPaydownAssetDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #PropertyTaxDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #GLManualJournalEntriesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
Create Table #GLManualJournalEntryDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #PayablesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create Table #TreasuryPayableDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #DisbursementRequestPayablesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
Create Table #DisbursementRequestPayeesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #PayableGLJournalsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #ChargeOffAssetDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #CollateralTrackingTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #CPIAssetMeterTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create Table #AssumptionAssetTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AppraisalDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #CPIScheduleAssetsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #CollateralAssetsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetSaleDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetSalesTradeInsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetEnMasseUpdateDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #BookDepreciationsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create TABLE #BookDepreciationEnMasseUpdateDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #BookDepreciationEnMasseSetupDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LienCollateralsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #SundryDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #SundryRecurringPaymentDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #CPIAssetMeterTypesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #UDFsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #WriteDownAssetDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LeaseAmendmentImpairmentAssetDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LeaseAssetPaymentSchedulesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #TaxDepEntitiesTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create Table #TaxDepAmortizationsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT , FeatureAsset Bit)
Create Table #TaxDepAmortizationDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #TaxDepEntityEnMasseUpdateDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LeaseAssetsTemp(RowNumber INT,NewId BIGINT,OldId BIGINT, NewAssetId BIGINT,OldAssetId BIGINT,IsLast BIT, OldCapitalizedForId BIGINT,FeatureAsset Bit,Prorate DECIMAL(18,10))
Create Table #LeaseAssetIncomeDetailsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #LeasePreclassificationResultsTemp(NewId BIGINT , OldId BIGINT , NewLeaseAssetID BIGINT, OldLeaseAssetID BIGINT,NewAssetId BIGINT,OldAssetId BIGINT)
Create Table #PayoffAssetsTemp (NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetFloatRateIncomesTemp(NewId BIGINT,OldId BIGINT, NewAssetId BIGINT,OldAssetId BIGINT)
Create Table #AssetIncomeSchedulesTemp(NewId BIGINT,OldId BIGINT, NewAssetId BIGINT,OldAssetId BIGINT)
Create Table #CapitalizedLeaseAssetsTemp(LeaseAssetId BIGINT,CapitalizedForId BIGINT)
Create Table #BlendedItemAssetsTemp(NewId BIGINT,OldId BIGINT,NewAssetId BIGINT, OldAssetId BIGINT)
CREATE TABLE #ReceivableDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
CREATE TABLE #ReceiptApplicationReceivableDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, OldPayableId BIGINT, FeatureAsset Bit)
CREATE TABLE #OneTimeACHReceivableDetailsTemp(NewId BIGINT,OldId BIGINT,NewAssetId BIGINT,OldAssetId BIGINT, FeatureAsset Bit)
CREATE TABLE #ReceivableInvoiceDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
CREATE TABLE #ReceivableTaxDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
CREATE TABLE #ReceivableTaxReversalDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
CREATE TABLE #ReceivableTaxImpositionsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT, FeatureAsset Bit)
CREATE TABLE #ReceiptApplicationReceivableTaxImpositionsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
CREATE TABLE #GLJournalDetailsTemp(NewId BIGINT , OldId BIGINT , NewAssetID BIGINT, OldAssetID BIGINT)
Create Table #AssetSplitAssetsTemp(NewId BIGINT , OldAssetId BIGINT)
Create Table #AssetSplitAssetsDetailTemp(NewId BIGINT , OldAssetId BIGINT , NewAssetId BIGINT)
Create Table #AssetFeatureSplitTemp (NewFeatureId BIGINT,OldFeatureId BIGINT,Prorate decimal(18,10) ,Value_Amount decimal(18,10),JobInstanceId BIGINT not null)
CREATE TABLE #ReceivableDetailInfo(Id BIGINT, ReceivableId BIGINT, Adjustment_Amount DECIMAL(16,2))
CREATE TABLE #ReceivableDetailInfoForFinanceAsset(Id BIGINT, ReceivableId BIGINT, Adjustment_Amount DECIMAL(16,2))

DECLARE @TotalNumOfSplit INT
DECLARE @DuplicateAssetCount INT
DECLARE @ColumnList VARCHAR(MAX)
DECLARE @InsertQuery VARCHAR(MAX)
DECLARE @UpdateQuery VARCHAR(MAX)
DECLARE @CommaSeparatedIds VARCHAR(MAX)
DECLARE @LastId VARCHAR(MAX);
DECLARE @TableName NVARCHAR(100);
DECLARE @RowVersionMiddle NVARCHAR(100);
DECLARE @RowVersionLast NVARCHAR(100);
DECLARE @PrimaryId NVARCHAR(100);
DECLARE @UpdateColumnName NVARCHAR(100);
DECLARE @IsAdvance BIT;
DECLARE @ContractMaturityDate DATETIME;
DECLARE @LeaseContractType NVARCHAR(100);
DECLARE @DueDay INT;
DECLARE @IsTaxLease Bit;
DECLARE @ContractIdToConsider BIGINT;
DECLARE @LeaseFinanceId BIGINT;
DECLARE @ContractAccountingStandard NVARCHAR(100);
DECLARE @ContractType NVARCHAR(100);
DECLARE @SyndicationType NVARCHAR(100);
DECLARE @PaymentFrequency NVARCHAR(100);


END
BEGIN
BEGIN TRY
BEGIN TRAN
-- Split Asset
Insert Into #SelectedAssets Select Id, FinancialType From Assets Where Id =  @AssetId
--Checking whether the contract Is advance or not
Select  @ContractMaturityDate = LeaseFinanceDetails.MaturityDate, @LeaseContractType = LeaseFinanceDetails.LeaseContractType,  @IsAdvance = LeaseFinanceDetails.IsAdvance, @DueDay = LeaseFinanceDetails.DueDay, @IsTaxLease = LeaseFinanceDetails.IsTaxLease , @ContractIdToConsider = LeaseFinances.ContractId, @LeaseFinanceId = LeaseFinances.Id, @ContractAccountingStandard = Contracts.AccountingStandard, @ContractType = LeaseFinanceDetails.LeaseContractType, @SyndicationType = SyndicationType , @PaymentFrequency = PaymentFrequency 
From LeaseAssets Join LeaseFinances On LeaseAssets.LeaseFinanceId = LeaseFinances.Id
Join LeaseFinanceDetails On LeaseFinances.Id = LeaseFinanceDetails.Id
Join Contracts on LeaseFinances.ContractId= Contracts.Id
Where LeaseAssets.AssetId = @AssetId And LeaseFinances.IsCurrent = 1

--Update Deferred Tax
If @IsTaxLease = 1
BEGIN

UPDATE DeferredTaxes SET IsReprocess = 0 where DeferredTaxes.ContractId = @ContractIdToConsider and IsScheduled = 1 and IsAccounting = 1
UPDATE DeferredTaxes SET IsReprocess = 1 where Id = (Select Top 1 Id from DeferredTaxes DT where DT.ContractId = @ContractIdToConsider and IsScheduled = 1 and IsAccounting = 1  order by DT.Date ) --and IsMigrated = 0

END

-- TakeDown Negative Assets
Insert Into #SelectedAssets
Select Distinct Negative.AssetId, 'NegativeDeposit' From PayableInvoiceAssets
Join PayableInvoiceDepositTakeDownAssets On PayableInvoiceDepositTakeDownAssets.TakeDownAssetId = PayableInvoiceAssets.Id
Join PayableInvoiceAssets Negative On Negative.Id = PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId
Where PayableInvoiceAssets.AssetId = @AssetId
-- Deposit Negative Assets
Insert Into #SelectedAssets
Select Distinct Negative.AssetId, 'NegativeDeposit' From PayableInvoiceAssets
Join PayableInvoiceDepositAssets On PayableInvoiceDepositAssets.DepositAssetId = PayableInvoiceAssets.Id
Join PayableInvoiceDepositTakeDownAssets On PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId = PayableInvoiceDepositAssets.Id
Join PayableInvoiceAssets Negative On Negative.Id = PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId
Where PayableInvoiceAssets.AssetId = @AssetId
-- Capitalized Assets
INSERT INTO #SelectedAssets
SELECT Distinct CapitalizedLeaseAssets.AssetId,'Soft' FROM LeaseAssets
JOIN LeaseAssets As CapitalizedLeaseAssets ON CapitalizedLeaseAssets.CapitalizedForId = LeaseAssets.Id
WHERE LeaseAssets.AssetId = @AssetId AND CapitalizedLeaseAssets.AssetId IS NOT NULL
-- Sales Tax Assets Capitalized For Capitalized Assets
INSERT INTO #SelectedAssets
SELECT Distinct CapitalizedSalesTaxAssets.AssetId,'SalesTax' FROM LeaseAssets
JOIN #SelectedAssets ON #SelectedAssets.SelectedAssetId = LeaseAssets.AssetId AND FinancialType = 'Soft'
JOIN LeaseAssets CapitalizedSalesTaxAssets ON CapitalizedSalesTaxAssets.CapitalizedForId = LeaseAssets.Id
WHERE
CapitalizedSalesTaxAssets.AssetId IS NOT NULL
AND CapitalizedSalesTaxAssets.AssetId NOT IN (SELECT SelectedAssetId FROM #SelectedAssets)
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO #DuplicateAssets
SELECT SelectedAssetId, 0, AD.Prorate , FinancialType , Quantity ,  0 FROM #SelectedAssets , @AssetDetail AD
INSERT INTO #DuplicateAssets
SELECT SelectedAssetId, 1, 1 - SUM(AD.Prorate) , FinancialType ,Quantity, 1 FROM #SelectedAssets , @AssetDetail  AD Group By SelectedAssetId , FinancialType ,Quantity
END
ELSE
BEGIN
INSERT INTO #DuplicateAssets
SELECT SelectedAssetId, 0, AD.Prorate , FinancialType ,Quantity, IsLastAsset FROM #SelectedAssets , @AssetDetail AD
END
BEGIN -- Asset Related Tables
BEGIN   -- Assets
SET @TableName = 'Assets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[Alias],' , '');
SET @ColumnList = REPLACE(@columnList, '[Quantity],' , '');
SET @ColumnList = REPLACE(@columnList, '[FinancialType],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[Alias]' , '');
SET @ColumnList = REPLACE(@columnList, ',[Quantity]' , '');
SET @ColumnList = REPLACE(@columnList, ',[FinancialType]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');


SET @InsertQuery = 'MERGE INTO Assets AS T1
USING (SELECT #DuplicateAssets.IsLastAsset , #DuplicateAssets.RowNum ,Id ,Prorate, FeatureAsset,Assets.FinancialType ,#DuplicateAssets.FinancialType ''DuplicateFinancialType''  ,#DuplicateAssets.Quantity , ' + @ColumnList + ' FROM Assets
JOIN #DuplicateAssets On #DuplicateAssets.DuplicateAssetId = Assets.Id Where #DuplicateAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', Alias , FinancialType , Quantity , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', CONVERT( VARCHAR(24), SYSDATETIMEOFFSET(), 113) + CAST (RowNum  AS VARCHAR(MAX)) , FinancialType , Quantity , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id, S1.Id, S1.IsLastAsset, S1.Prorate, S1.FeatureAsset,0, S1.DuplicateFinancialType, S1.Quantity , 0, 0  INTO #SplitedAssets;';

IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'Insert Into #SplitedAssets Select DuplicateAssetId, DuplicateAssetId, 1, Prorate, 1 ,0, FinancialType, Quantity , 0, 0  From #DuplicateAssets Where FeatureAsset = 1;';
END
EXEC(@InsertQuery)
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
;WITH CTE_LastAsset AS
(
SELECT OldAssetID, MAX(NewAssetID) [NewAssetID] FROM #SplitedAssets GROUP BY OldAssetID
)
UPDATE #SplitedAssets SET IsLastAsset = 1 FROM #SplitedAssets
Inner Join CTE_LastAsset ON CTE_LastAsset.NewAssetID = #SplitedAssets.NewAssetID;
END
;WITH CTE_RowNum AS
(
SELECT NewAssetID , ROW_NUMBER() OVER (PARTITION by OldAssetId ORDER BY NewAssetId DESC) 'ROWNUM' FROM #SplitedAssets
)
UPDATE #SplitedAssets SET RowNum = CTE_RowNum.ROWNUM
FROM #SplitedAssets JOIN CTE_RowNum ON #SplitedAssets.NewAssetID = CTE_RowNum.NewAssetID;
Delete From AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
Select NewAssetID, OldAssetID, Prorate, IsLastAsset, @JobInstanceId  From #SplitedAssets;
SET @UpdateColumnName = 'Id';
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE Assets SET Status = ''Scrap'' FROM Assets JOIN #SelectedAssets ON Assets.Id = #SelectedAssets.SelectedAssetId'
END
;WITH CTE_RowNumberByFinancialType AS
(
SELECT RowNum , ROW_NUMBER() OVER (Partition By FinancialType Order by OldAssetId) as RowNumByFinancialType  FROM  #SplitedAssets
)
UPDATE #SplitedAssets SET RowNumByFinancialType = CTE_RowNumberByFinancialType.RowNumByFinancialType
FROM #SplitedAssets JOIN CTE_RowNumberByFinancialType ON #SplitedAssets.RowNum = CTE_RowNumberByFinancialType.RowNum
INSERT INTO #AssetParameter
SELECT AssetFeatureId , AssetId , NewAmount , Alias FROM @AssetDetail
SET @UpdateQuery = @UpdateQuery + ' Update Assets Set Alias = Id  From Assets Join AssetSplitTemp On  AssetSplitTemp.NewId = Assets.Id
Join #SplitedAssets on AssetSplitTemp.NewId = #SplitedAssets.NewAssetId Where #SplitedAssets.FeatureAsset = 0 and AssetSplitTemp.JobInstanceId='+@JobInstanceIdInString +';';
SET @UpdateQuery = @UpdateQuery + ' Update Assets Set Alias = #AssetParameter.Alias 
From Assets
Join #SplitedAssets On  Assets.Id  = #SplitedAssets.NewAssetId
Join #AssetParameter On #SplitedAssets.RowNumByFinancialType = #AssetParameter.RowNum
WHERE #SplitedAssets.FinancialType = ''Real'';'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE Assets SET FeatureSetId = NULL
FROM ASSETS JOIN #SplitedAssets ON Assets.Id = #SplitedAssets.NewAssetId
WHERE #SplitedAssets.FeatureAsset = 0 AND #SplitedAssets.FinancialType = ''Real'';'
SET @UpdateQuery = @UpdateQuery + ' Update Assets Set ManufacturerId = AssetFeatures.ManufacturerId , Quantity= AssetFeatures.Quantity, MakeId=AssetFeatures.MakeId, ModelId=AssetFeatures.ModelId, AssetCatalogId=AssetFeatures.AssetCatalogId ,AssetCategoryId=AssetFeatures.AssetCategoryId, ProductId=AssetFeatures.ProductId
From Assets
Join #SplitedAssets On  Assets.Id  = #SplitedAssets.NewAssetId
Join #AssetParameter On #SplitedAssets.RowNumByFinancialType = #AssetParameter.RowNum
Join AssetFeatures On #AssetParameter.AssetFeatureId = AssetFeatures.Id
WHERE #SplitedAssets.FinancialType = ''Real'';'
END
Exec (@UpdateQuery)
BEGIN   -- Asset SerialNumber
	IF @SplitByType <> 'AssetSplitFeature'
	BEGIN
		SET @InsertQuery = 'MERGE INTO AssetSerialNumbers AS T1
			USING (SELECT ASN.Id,ASN.SerialNumber AS NewSerialNumber , A.Id As NewAssetId, ASD.OriginalAssetId As OldAssetId  FROM AssetSerialNumbers ASN 
			JOIN AssetSerialNumberSplitDetailInfoes ASNSDI ON ASN.Id = ASNSDI.AssetSerialNumberId AND  ASNSDI.IsActive = 1
			JOIN AssetSplitDetailInfoes ASDI ON ASNSDI.AssetSplitDetailInfoId = ASDI.Id AND ASDI.IsActive = 1
			JOIN AssetSplitDetails ASD ON ASDI.AssetSplitDetailId = ASD.Id AND ASD.IsActive = 1
			JOIN AssetSplits on ASD.AssetSplitId = AssetSplits.Id
			JOIN Assets A ON A.Alias = ASDI.Alias
			WHERE AssetSplits.Id=  '+ CAST(@AssetSplitId AS NVARCHAR(10)) +'  AND ASN.IsActive = 1) AS S1 ON 1=0
			WHEN NOT MATCHED THEN
			INSERT ( [SerialNumber],[IsActive],[AssetId],[CreatedById],[CreatedTime] ) VALUES
			(
			 NewSerialNumber, 1, NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
			)OUTPUT Inserted.Id, S1.Id AS OldId, S1.NewAssetId, S1.OldAssetId Into #AssetSerialNumbersTemp;'
		EXEC(@InsertQuery)

		SET @UpdateQuery ='UPDATE AssetSerialNumbers SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetSerialNumbers JOIN #AssetSerialNumbersTemp ON AssetSerialNumbers.Id = #AssetSerialNumbersTemp.OldId'

		EXEC(@UpdateQuery)
	END
    ELSE
	BEGIN
		SET @InsertQuery ='MERGE INTO AssetSerialNumbers AS T1
			USING (
		SELECT CFAD.AssetFeatureId,CFSASD.SerialNumber AS NewSerialNumber , AF.AssetId AS OldAssetID , A.Id AS NewAssetID
		FROM #AssetParameter AF
		JOIN ConvertFeatureToAssetDetails CFAD ON CFAD.AssetFeatureId = AF.AssetFeatureId AND CFAD.IsActive = 1
		JOIN ConvertFeatureSerialToAssetSerialDetails CFSASD ON CFSASD.ConvertFeatureToAssetDetailId = CFAD.Id AND CFSASD.IsActive = 1
		JOIN Assets A ON AF.Alias = A.Alias) AS S1 ON 1=0
		WHEN NOT MATCHED THEN
			INSERT ( [SerialNumber],[IsActive],[AssetId],[CreatedById],[CreatedTime] ) VALUES
			(
			 NewSerialNumber, 1, NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
			);';
		EXEC(@InsertQuery)

		SET @UpdateQuery ='UPDATE AssetFeatureSerialNumbers SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetFeatureSerialNumbers JOIN #AssetParameter ON AssetFeatureSerialNumbers.AssetFeatureId = #AssetParameter.AssetFeatureId'

		EXEC(@UpdateQuery)
	END
END
END
BEGIN   -- Asset Feature
SET @TableName = 'AssetFeatures';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[Quantity],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[Quantity]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');


BEGIN
SET @InsertQuery = 'MERGE INTO AssetFeatures AS T1
USING (SELECT '+ @ColumnList + ',Id  , NewAssetId , OldAssetId,FeatureAsset ,AssetFeatures.Quantity  FROM AssetFeatures
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetFeatures.AssetId
WHERE #SplitedAssets.FeatureAsset = 0  AND (''' + CAST(@SplitByType AS VARCHAR(MAX)) + ''' <> ''AssetSplitFeature'' OR #SplitedAssets.FinancialType <> ''Real'')) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  ,AssetId , Quantity , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , Quantity , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #AssetFeaturesTemp;'
END
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO #AssetParameter
SELECT AssetFeatureId , AssetId , NewAmount , Alias FROM @AssetDetail ORDER BY AssetFeatureId DESC
END
--	SET @InsertQuery = @InsertQuery + 'MERGE INTO AssetFeatures AS T1
--			USING (SELECT '+ @ColumnList + 'Id  , NewAssetId , OldAssetId,FeatureAsset  , AssetFeatures.Quantity FROM AssetFeatures
--			JOIN #AssetParameter On #AssetParameter.AssetFeatureId = AssetFeatures.Id
--			JOIN #SplitedAssets On #SplitedAssets.OldAssetId = #AssetParameter.AssetId AND #SplitedAssets.RowNum = #AssetParameter.RowNum) AS S1 ON 1=0
--			WHEN NOT MATCHED THEN
--			INSERT ( ' + @ColumnList + '  AssetId , Quantity ) VALUES
--			(
--			' + @ColumnList + ' NewAssetId , Quantity
--			)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #AssetFeaturesTemp;'
--END
EXEC(@InsertQuery)
-- Update Asset Feature
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId , OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetFeaturesTemp join #SplitedAssets On #AssetFeaturesTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetFeatures SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetFeatures JOIN #AssetParameter On AssetFeatures.Id = #AssetParameter.AssetFeatureId ; '
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetFeatures SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetFeatures JOIN #AssetFeaturesTemp ON AssetFeatures.Id = #AssetFeaturesTemp.OldId ;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE Assets SET Assets.TypeId = AssetFeatures.TypeId , Assets.StateId = AssetFeatures.StateId , Assets.Description = AssetTypes.Name
FROM Assets JOIN
#SplitedAssets on Assets.Id = #SplitedAssets.NewAssetID
JOIN #AssetParameter ON #SplitedAssets.RowNumByFinancialType = #AssetParameter.RowNum AND #SplitedAssets.FinancialType = ''Real''
JOIN AssetFeatures ON #AssetParameter.AssetFeatureId = assetfeatures.Id
JOIN AssetTypes ON AssetFeatures.TypeId = AssetTypes.Id
where #SplitedAssets.FeatureAsset = 0';
END
EXEC(@UpdateQuery)
--Updating the Value for each Feature
IF (@SplitByType <> 'AssetSplitFeature')
BEGIN
insert into #AssetFeatureSplitTemp
select NewId,OldId,Prorate,assetFeatures.Value_Amount,JobInstanceId from AssetSplitTemp assetSplitTemp join AssetFeatures assetFeatures on assetSplitTemp.NewId=assetfeatures.Id;
With CTE_1 as (
select assetFeatureSplitTemp.OldFeatureId,Sum(assetFeatureSplitTemp.Value_Amount) NewTotalValue  from #AssetFeatureSplitTemp assetFeatureSplitTemp group by OldFeatureId
),
CTE_2 as  (
select cte1.OldFeatureId, assetFeature.Value_Amount-NewTotalValue ValueDiff , ABS(assetFeature.Value_Amount-NewTotalValue)*100 No_Of_Feature,
AdjustmentValue = CASE
WHEN (assetFeature.Value_Amount-NewTotalValue)>0 THEN 0.01
WHEN (assetFeature.Value_Amount-NewTotalValue)<0 THEN -0.01
ELSE 0.00
END
from CTE_1 cte1 join AssetFeatures assetFeature on cte1.OldFeatureId=assetFeature.Id
)
select * into #FeatureSplitInfo from CTE_2;
WITH CTE_OrderedSplit
AS
(
SELECT
NewFeatureId,OldFeatureId,Prorate ,Value_Amount ,JobInstanceId ,
ROW_NUMBER() OVER (PARTITION BY #AssetFeatureSplitTemp.OldFeatureId ORDER BY #AssetFeatureSplitTemp.Value_Amount DESC) RowNumber
FROM
#AssetFeatureSplitTemp
),CTE_Result
as
(
select NewFeatureId ,orderedSplit.Value_Amount + #FeatureSplitInfo.AdjustmentValue  NewValue
FROM CTE_OrderedSplit orderedSplit
INNER JOIN #FeatureSplitInfo ON   orderedSplit.OldFeatureId = #FeatureSplitInfo.OldFeatureId AND
orderedSplit.RowNumber <= #FeatureSplitInfo.No_Of_Feature
)
Update
#AssetFeatureSplitTemp
set Value_Amount=NewValue
from #AssetFeatureSplitTemp
JOIN CTE_Result ON #AssetFeatureSplitTemp.NewFeatureId=CTE_Result.NewFeatureId
UPDATE assetFeatures set assetFeatures.Value_Amount= assetFeatureSplitTemp.Value_Amount
from  AssetFeatures assetFeatures
join #AssetFeatureSplitTemp assetFeatureSplitTemp on assetFeatures.Id=assetFeatureSplitTemp.NewFeatureId
where assetFeatureSplitTemp.JobInstanceId=@JobInstanceId;
END
END
BEGIN   -- Asset Location
SET @TableName = 'AssetLocations';
SET @ColumnList = dbo.GetColumnList(@TableName);

SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetLocations AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , FeatureAsset FROM AssetLocations
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetLocations.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #AssetLocationsTemp;'
EXEC(@InsertQuery)

--Update Asset Location
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetLocationsTemp join #SplitedAssets On #AssetLocationsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #AssetLocationsTemp join #SplitedAssets On #AssetLocationsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetLocations SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetLocations JOIN #AssetLocationsTemp ON AssetLocations.Id = #AssetLocationsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Asset Meters
SET @TableName = 'AssetMeters';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetMeters AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetMeters
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetMeters.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetMetersTemp;'
EXEC(@InsertQuery)
--Update Asset Meter
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #AssetMetersTemp join #SplitedAssets On #AssetMetersTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetMeters SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetMeters JOIN #AssetMetersTemp ON AssetMeters.Id = #AssetMetersTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Asset Histories
SET @TableName = 'AssetHistories';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[FinancialType],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[FinancialType]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetHistories AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , AssetHistories.[FinancialType] FROM AssetHistories
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetHistories.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , FinancialType , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , FinancialType , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetHistoriesTemp;'
EXEC(@InsertQuery)
IF @SplitByType <> 'AssetSplitFeature'
BEGIN   -- Asset Histories scrap status change for old record
SET @TableName = 'AssetHistories';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[Status],' , '');
SET @ColumnList = REPLACE(@columnList, '[Reason],' , '');
SET @ColumnList = REPLACE(@columnList, '[SourceModule],' , '');
SET @ColumnList = REPLACE(@columnList, '[SourceModuleId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AsOfDate],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[Status]' , '');
SET @ColumnList = REPLACE(@columnList, ',[Reason]' , '');
SET @ColumnList = REPLACE(@columnList, ',[SourceModule]' , '');
SET @ColumnList = REPLACE(@columnList, ',[SourceModuleId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AsOfDate]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

INSERT INTO #AssetHistoriesMaxTemp
SELECT MAX(Id) , AssetHistories.AssetId FROM AssetHistories
JOIN #SelectedAssets ON AssetHistories.AssetId = #SelectedAssets.SelectedAssetId
GROUP BY AssetHistories.AssetId
SET @InsertQuery = 'MERGE INTO AssetHistories AS T1
USING (SELECT ' + @ColumnList + ', AssetHistories.AssetId FROM AssetHistories
JOIN #AssetHistoriesMaxTemp on AssetHistories.Id = #AssetHistoriesMaxTemp.Id AND AssetHistories.AssetId = #AssetHistoriesMaxTemp.AssetId) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , Status , Reason , SourceModule , SourceModuleId , AsOfDate , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',   AssetId , ''Scrap'' , ''StatusChange'' , ''AssetSplit'', ' + CAST(@AssetSplitId AS VARCHAR(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + ''' , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
);'
EXEC(@InsertQuery)
END
--Update Asset History
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #AssetHistoriesTemp join #SplitedAssets On #AssetHistoriesTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
SET @UpdateQuery = @UpdateQuery + 'Update AssetHistories SET SourceModule = ''AssetSplit'', SourceModuleId = ' + CAST(@AssetSplitId AS VARCHAR(MAX)) +' FROM AssetHistories
JOIN #AssetHistoriesTemp ON AssetHistories.Id = #AssetHistoriesTemp.NewId;';
EXEC(@UpdateQuery)
END
BEGIN -- Asset Split Assets
SET @TableName = 'AssetSplitAssets';
SET @InsertQuery = 'MERGE INTO AssetSplitAssets AS T1
USING (SELECT Assets.Id ,Assets.Quantity, #SelectedAssets.SelectedAssetId FROM Assets
JOIN #SelectedAssets On Assets.Id = #SelectedAssets.SelectedAssetId) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( SplitByType, OriginalAssetCost_Amount, OriginalAssetCost_Currency, OriginalQuantity, CreatedById, CreatedTime, UpdatedById, UpdatedTime,  OriginalAssetId )VALUES
(
''' + CAST(@SplitByType AS VARCHAR(MAX)) +'''
,0.00
,''' + CAST(@Currency AS VARCHAR(3))+'''
,Quantity
,' + CAST (@UserId AS VARCHAR(max)) +'
, ''' + Cast( + @Time as Varchar(MAX)) +'''
,null
,null
,SelectedAssetId
)
OUTPUT Inserted.Id ,S1.Id Into #AssetSplitAssetsTemp;';
EXEC(@InsertQuery)
SET @UpdateQuery =
';WITH CTE_AssetCost_Updation AS
(
SELECT AssetValueHistories.AssetId , AssetValueHistories.Cost_Amount , ROW_NUMBER() OVER (PARTITION BY AssetId ORDER BY AssetValueHistories.IncomeDate , AssetValueHistories.Id DESC) AS [HistoryRowNum]
FROM #SelectedAssets JOIN AssetValueHistories ON #SelectedAssets.SelectedAssetId = AssetValueHistories.AssetId
WHERE (AssetValueHistories.SourceModule = ''PayableInvoice'' OR  AssetValueHistories.SourceModule = ''LoanBooking'' OR  AssetValueHistories.SourceModule = ''LeaseBooking'' OR AssetValueHistories.SourceModule = ''AssetValueAdjustment'' OR AssetValueHistories.SourceModule = ''AssetProfile'')
AND AssetValueHistories.IsLessorOwned = 1
)
,CTE_AssetSplitAssets AS
(
SELECT AssetSplitAssets.OriginalAssetId , max(AssetSplitAssets.Id) AS MaxAssetSplitId
FROM AssetSplitAssets JOIN #SelectedAssets ON AssetSplitAssets.OriginalAssetId = #SelectedAssets.SelectedAssetId
GROUP BY AssetSplitAssets.OriginalAssetId
)
Update AssetSplitAssets SET OriginalAssetCost_Amount = CTE_AssetCost_Updation.Cost_Amount
FROM AssetSplitAssets
JOIN CTE_AssetCost_Updation ON AssetSplitAssets.OriginalAssetId = CTE_AssetCost_Updation.AssetId
JOIN CTE_AssetSplitAssets ON AssetSplitAssets.Id = CTE_AssetSplitAssets.MaxAssetSplitId
WHERE CTE_AssetCost_Updation.HistoryRowNum = 1'
EXEC(@UpdateQuery)
END
BEGIN   --  Asset Value Histories
SET @TableName = 'AssetValueHistories';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetValueHistories AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId,FeatureAsset FROM AssetValueHistories
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetValueHistories.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId,S1.FeatureAsset Into #AssetValueHistoriesTemp;'
EXEC(@InsertQuery)
--Update Asset Value History
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #AssetValueHistoriesTemp join #SplitedAssets On #AssetValueHistoriesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #AssetValueHistoriesTemp join #SplitedAssets On #AssetValueHistoriesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetValueHistories SET IsSchedule = 0, IsAccounted = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetValueHistories JOIN #AssetValueHistoriesTemp ON AssetValueHistories.Id = #AssetValueHistoriesTemp.OldId'
END
EXEC(@UpdateQuery)
SET @UpdateQuery = 'Update AssetValueHistories Set Value_Amount = EndBookValue_Amount - BeginBookValue_Amount From AssetValueHistories JOIN #SplitedAssets On #SplitedAssets.NewAssetId = AssetValueHistories.AssetId WHERE #SplitedAssets.FeatureAsset = 0 AND (SourceModule = ''FixedTermDepreciation'' OR SourceModule = ''InventoryBookDepreciation'' OR SourceModule = ''OTPDepreciation'');';
EXEC(@UpdateQuery)
END
BEGIN   --  Asset Value History Details
SET @TableName = 'AssetValueHistoryDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetValueHistoryId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetValueHistoryId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetValueHistoryDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , NewId FROM AssetValueHistoryDetails
JOIN #AssetValueHistoriesTemp on AssetValueHistoryDetails.AssetValUeHistoryId = #AssetValueHistoriesTemp.OldId Where #AssetValueHistoriesTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  AssetValueHistoryId , CreatedById , CreatedTime  ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetValueHistoryDetailsTemp;'
EXEC(@InsertQuery)
--Update Asset Value History Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetValueHistoryDetailsTemp join #SplitedAssets On #AssetValueHistoryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #AssetValueHistoryDetailsTemp join #SplitedAssets On #AssetValueHistoryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetValueHistoryDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetValueHistoryDetails JOIN #AssetValueHistoryDetailsTemp ON AssetValueHistoryDetails.Id = #AssetValueHistoryDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  Asset Location Change Details
SET @TableName = 'AssetsLocationChangeDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetsLocationChangeDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetsLocationChangeDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetsLocationChangeDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetsLocationChangeDetailsTemp;'
EXEC(@InsertQuery)
--Update Asset Location Change Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetsLocationChangeDetailsTemp join #SplitedAssets On #AssetsLocationChangeDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #AssetsLocationChangeDetailsTemp join #SplitedAssets On #AssetsLocationChangeDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
EXEC(@UpdateQuery)
END
BEGIN   --  Asset Value Status Change Details
SET @TableName = 'AssetsValueStatusChangeDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetsValueStatusChangeDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetsValueStatusChangeDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetsValueStatusChangeDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetsValueStatusChangeDetailsTemp;'
EXEC(@InsertQuery)
--Update Asset Value Status Change Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId from #AssetsValueStatusChangeDetailsTemp join #SplitedAssets On #AssetsValueStatusChangeDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #AssetsValueStatusChangeDetailsTemp join #SplitedAssets On #AssetsValueStatusChangeDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetsValueStatusChangeDetails SET NewStatus = ''Scrap'', UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetsValueStatusChangeDetails JOIN #AssetsValueStatusChangeDetailsTemp ON AssetsValueStatusChangeDetails.Id = #AssetsValueStatusChangeDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  Billed Rental Receivables
SET @TableName = 'VertexBilledRentalReceivables';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO VertexBilledRentalReceivables AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM VertexBilledRentalReceivables
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = VertexBilledRentalReceivables.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #VertexBilledRentalReceivablesTemp;'
EXEC(@InsertQuery)
--Update Billed Rental Receivables
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #VertexBilledRentalReceivablesTemp join #SplitedAssets On #VertexBilledRentalReceivablesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #VertexBilledRentalReceivablesTemp join #SplitedAssets On #VertexBilledRentalReceivablesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE VertexBilledRentalReceivables SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM VertexBilledRentalReceivables JOIN #VertexBilledRentalReceivablesTemp ON VertexBilledRentalReceivables.Id = #VertexBilledRentalReceivablesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  Maturity Monitor FMV Asset Details
SET @TableName = 'MaturityMonitorFMVAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO MaturityMonitorFMVAssetDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM MaturityMonitorFMVAssetDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = MaturityMonitorFMVAssetDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #MaturityMonitorFMVAssetDetailsTemp;'
EXEC(@InsertQuery)
--Update Maturity Monitor FMV Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #MaturityMonitorFMVAssetDetailsTemp join #SplitedAssets On #MaturityMonitorFMVAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #MaturityMonitorFMVAssetDetailsTemp join #SplitedAssets On #MaturityMonitorFMVAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE MaturityMonitorFMVAssetDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM MaturityMonitorFMVAssetDetails JOIN #MaturityMonitorFMVAssetDetailsTemp ON MaturityMonitorFMVAssetDetails.Id = #MaturityMonitorFMVAssetDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  Loan Paydown Asset Details
SET @TableName = 'LoanPaydownAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO LoanPaydownAssetDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM LoanPaydownAssetDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = LoanPaydownAssetDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #LoanPaydownAssetDetailsTemp;'
EXEC(@InsertQuery)
--Update Loan Paydown Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #LoanPaydownAssetDetailsTemp join #SplitedAssets On #LoanPaydownAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #LoanPaydownAssetDetailsTemp join #SplitedAssets On #LoanPaydownAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE LoanPaydownAssetDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM LoanPaydownAssetDetails JOIN #LoanPaydownAssetDetailsTemp ON LoanPaydownAssetDetails.Id = #LoanPaydownAssetDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  Property Tax Details
SET @TableName = 'PropertyTaxDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO PropertyTaxDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM PropertyTaxDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = PropertyTaxDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #PropertyTaxDetailsTemp;'
EXEC(@InsertQuery)
--Update Property Tax Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #PropertyTaxDetailsTemp join #SplitedAssets On #PropertyTaxDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #PropertyTaxDetailsTemp join #SplitedAssets On #PropertyTaxDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName,@UserId , @SplitByType,@Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE PropertyTaxDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM PropertyTaxDetails JOIN #PropertyTaxDetailsTemp ON PropertyTaxDetails.Id = #PropertyTaxDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  GL Manual Journal Entries
SET @TableName = 'GLManualJournalEntries';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO GLManualJournalEntries AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , FeatureAsset FROM GLManualJournalEntries
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = GLManualJournalEntries.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   AssetId, CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #GLManualJournalEntriesTemp;'
EXEC(@InsertQuery)
--Update GL Manual Journal Entries
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #GLManualJournalEntriesTemp join #SplitedAssets On #GLManualJournalEntriesTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE GLManualJournalEntries SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM GLManualJournalEntries JOIN #GLManualJournalEntriesTemp ON GLManualJournalEntries.Id = #GLManualJournalEntriesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   --  GL Manual Journal Entry Details
SET @TableName = 'GLManualJournalEntryDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[GLManualJournalEntryId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[GLManualJournalEntryId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO GLManualJournalEntryDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , NewId , FeatureAsset FROM GLManualJournalEntryDetails
JOIN #GLManualJournalEntriesTemp ON GLManualJournalEntryDetails.GLManualJournalEntryId = #GLManualJournalEntriesTemp.OldId Where #GLManualJournalEntriesTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   GLManualJournalEntryId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #GLManualJournalEntryDetailsTemp;'
EXEC(@InsertQuery)
--Update GL Manual Journal Entry Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #GLManualJournalEntryDetailsTemp join #SplitedAssets On #GLManualJournalEntryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #GLManualJournalEntryDetailsTemp join #SplitedAssets On #GLManualJournalEntryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE GLManualJournalEntryDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM GLManualJournalEntryDetails JOIN #GLManualJournalEntryDetailsTemp ON GLManualJournalEntryDetails.Id = #GLManualJournalEntryDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Charge Off Asset Details
SET @TableName = 'ChargeOffAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ChargeOffAssetDetails AS T1
USING (SELECT '+ @ColumnList + ',Id , NewAssetId , OldAssetId FROM ChargeOffAssetDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = ChargeOffAssetDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #ChargeOffAssetDetailsTemp;'
EXEC(@InsertQuery)
--Update Charge Off Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #ChargeOffAssetDetailsTemp join #SplitedAssets On #ChargeOffAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #ChargeOffAssetDetailsTemp join #SplitedAssets On #ChargeOffAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ChargeOffAssetDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ChargeOffAssetDetails JOIN #ChargeOffAssetDetailsTemp ON ChargeOffAssetDetails.Id = #ChargeOffAssetDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Collateral Tracking
SET @TableName = 'CollateralTrackings';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetLocationId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetLocationId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO CollateralTrackings AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM CollateralTrackings
JOIN #SplitedAssets on #SplitedAssets.OldAssetId = CollateralTrackings.AssetId  WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #CollateralTrackingTemp;'
EXEC(@InsertQuery)
--Update Collateral Tracking
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #CollateralTrackingTemp join #SplitedAssets On #CollateralTrackingTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE CollateralTrackings SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM CollateralTrackings JOIN #CollateralTrackingTemp ON CollateralTrackings.Id = #CollateralTrackingTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- CPI Asset Meter
SET @TableName = 'CPIAssetMeters';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO CPIAssetMeters AS T1
USING (SELECT '+ @ColumnList + ',Id , NewAssetId , OldAssetId , FeatureAsset FROM CPIAssetMeters
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = CPIAssetMeters.AssetId  WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #CPIAssetMeterTemp;'
EXEC(@InsertQuery)
--Update CPI Asset Meter
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #CPIAssetMeterTemp join #SplitedAssets On #CPIAssetMeterTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE CPIAssetMeters SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM CPIAssetMeters JOIN #CPIAssetMeterTemp ON CPIAssetMeters.Id = #CPIAssetMeterTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- CPI Asset Meter Types
SET @TableName = 'CPIAssetMeterTypes';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[CPIAssetMeterId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[CPIAssetMeterId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO CPIAssetMeterTypes AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #CPIAssetMeterTemp.NewId FROM CPIAssetMeterTypes
JOIN #CPIAssetMeterTemp on CPIAssetMeterTypes.CPIAssetMeterId = #CPIAssetMeterTemp.OldId WHERE #CPIAssetMeterTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  CPIAssetMeterId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #CPIAssetMeterTypesTemp;
UPDATE CPIAssetMeterTypes
SET OldReading = 0, NewReading = 0
FROM CPIAssetMeterTypes CA
JOIN AssetSplitTemp AST ON CA.CPIAssetMeterId = AST.NewId and AST.JobInstanceId='+@JobInstanceIdInString +';'
EXEC(@InsertQuery)
--Update CPI Asset Meter Types
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #CPIAssetMeterTypesTemp join #SplitedAssets On #CPIAssetMeterTypesTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
EXEC(@UpdateQuery)
END
BEGIN   -- Appraisal Details
SET @TableName = 'AppraisalDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AppraisalDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AppraisalDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AppraisalDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AppraisalDetailsTemp;'
EXEC(@InsertQuery)
--Update Appraisal Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AppraisalDetailsTemp join #SplitedAssets On #AppraisalDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #AppraisalDetailsTemp join #SplitedAssets On #AppraisalDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AppraisalDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AppraisalDetails JOIN #AppraisalDetailsTemp ON AppraisalDetails.Id = #AppraisalDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- CPI Schedule Assets
SET @TableName = 'CPIScheduleAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO CPIScheduleAssets AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM CPIScheduleAssets
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = CPIScheduleAssets.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #CPIScheduleAssetsTemp;'
EXEC(@InsertQuery)
--Update CPI Schedule Assets
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #CPIScheduleAssetsTemp join #SplitedAssets On #CPIScheduleAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #CPIScheduleAssetsTemp join #SplitedAssets On #CPIScheduleAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE CPIScheduleAssets SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM CPIScheduleAssets JOIN #CPIScheduleAssetsTemp ON CPIScheduleAssets.Id = #CPIScheduleAssetsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Collateral Assets
SET @TableName = 'CollateralAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO CollateralAssets AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM CollateralAssets
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = CollateralAssets.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #CollateralAssetsTemp;'
EXEC(@InsertQuery)
--Update Collateral Assets
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #CollateralAssetsTemp join #SplitedAssets On #CollateralAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #CollateralAssetsTemp join #SplitedAssets On #CollateralAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE CollateralAssets SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM CollateralAssets JOIN #CollateralAssetsTemp ON CollateralAssets.Id = #CollateralAssetsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Asset Sale Details
SET @TableName = 'AssetSaleDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetSaleDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetSaleDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetSaleDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetSaleDetailsTemp;'
EXEC(@InsertQuery)
--Update Asset Sale Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetSaleDetailsTemp join #SplitedAssets On #AssetSaleDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #AssetSaleDetailsTemp join #SplitedAssets On #AssetSaleDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetSaleDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetSaleDetails JOIN #AssetSaleDetailsTemp ON AssetSaleDetails.Id = #AssetSaleDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Asset Sale TradeIns
SET @TableName = 'AssetSalesTradeIns';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetSalesTradeIns AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetSalesTradeIns
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetSalesTradeIns.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetSalesTradeInsTemp;'
EXEC(@InsertQuery)
--Update Asset Sale TradeIns
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId  from #AssetSalesTradeInsTemp join #SplitedAssets On #AssetSalesTradeInsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId  from #AssetSalesTradeInsTemp join #SplitedAssets On #AssetSalesTradeInsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetSalesTradeIns SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetSalesTradeIns JOIN #AssetSalesTradeInsTemp ON AssetSalesTradeIns.Id = #AssetSalesTradeInsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Asset En-Masse Update Details
SET @TableName = 'AssetEnMasseUpdateDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[Quantity],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[Quantity]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetEnMasseUpdateDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId,AssetEnMasseUpdateDetails.Quantity FROM AssetEnMasseUpdateDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetEnMasseUpdateDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , Quantity , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId,Quantity , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetEnMasseUpdateDetailsTemp;'
EXEC(@InsertQuery)
--Update Asset En-Masse Update Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId   from #AssetEnMasseUpdateDetailsTemp join #SplitedAssets On #AssetEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId  from #AssetEnMasseUpdateDetailsTemp join #SplitedAssets On #AssetEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
EXEC(@UpdateQuery)
END
BEGIN   -- Book Depreciations
SET @TableName = 'BookDepreciations';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO BookDepreciations AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , FeatureAsset FROM BookDepreciations
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = BookDepreciations.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #BookDepreciationsTemp;'
EXEC(@InsertQuery)
--Update Book Depreciations
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId   from #BookDepreciationsTemp join #SplitedAssets On #BookDepreciationsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #BookDepreciationsTemp join #SplitedAssets On #BookDepreciationsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE BookDepreciations SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM BookDepreciations JOIN #BookDepreciationsTemp ON BookDepreciations.Id = #BookDepreciationsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- GLJournal Details Begin
SET @TableName = 'GLJournalDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[EntityId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[EntityId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO GLJournalDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM GLJournalDetails
JOIN #SplitedAssets ON GLJournalDetails.EntityType = ''Asset'' AND #SplitedAssets.OldAssetId = GLJournalDetails.EntityId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , EntityId  , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId  Into #GLJournalDetailsTemp;'
SET @InsertQuery = @InsertQuery + 'MERGE INTO GLJournalDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId, #BookDepreciationsTemp.NewId  FROM GLJournalDetails
JOIN #BookDepreciationsTemp ON GLJournalDetails.EntityType = ''BookDepreciation'' AND GLJournalDetails.EntityId = #BookDepreciationsTemp.OldId WHERE #BookDepreciationsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  EntityId  , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #GLJournalDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #GLJournalDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #GLJournalDetailsTemp join #SplitedAssets On #GLJournalDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, '+@JobInstanceIdInString +' from #GLJournalDetailsTemp join #SplitedAssets On #GLJournalDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
-- Update GLJournal Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE GLJournalDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM GLJournalDetails JOIN #GLJournalDetailsTemp ON GLJournalDetails.Id = #GLJournalDetailsTemp.OldId;'
END
EXEC(@UpdateQuery)
END -- GLJournal Details End
BEGIN   -- Book Depreciation En-Masse Update Details
SET @TableName = 'BookDepreciationEnMasseUpdateDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[BookDepreciationId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[BookDepreciationId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO BookDepreciationEnMasseUpdateDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , NewId , FeatureAsset FROM BookDepreciationEnMasseUpdateDetails
JOIN #BookDepreciationsTemp ON BookDepreciationEnMasseUpdateDetails.BookDepreciationId = #BookDepreciationsTemp.OldId Where #BookDepreciationsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',   BookDepreciationId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #BookDepreciationEnMasseUpdateDetailsTemp;'
EXEC(@InsertQuery)
--Update Book Depreciation En-Masse Update Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #BookDepreciationEnMasseUpdateDetailsTemp join #SplitedAssets On #BookDepreciationEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #BookDepreciationEnMasseUpdateDetailsTemp join #SplitedAssets On #BookDepreciationEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE BookDepreciationEnMasseUpdateDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM BookDepreciationEnMasseUpdateDetails JOIN #BookDepreciationEnMasseUpdateDetailsTemp ON BookDepreciationEnMasseUpdateDetails.Id = #BookDepreciationEnMasseUpdateDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Book Depreciation En-Masse Setup Details
SET @TableName = 'BookDepreciationEnMasseSetupDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO BookDepreciationEnMasseSetupDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM BookDepreciationEnMasseSetupDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = BookDepreciationEnMasseSetupDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #BookDepreciationEnMasseSetupDetailsTemp;'
EXEC(@InsertQuery)
--Update Book Depreciation En-Masse Setup Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #BookDepreciationEnMasseSetupDetailsTemp join #SplitedAssets On #BookDepreciationEnMasseSetupDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #BookDepreciationEnMasseSetupDetailsTemp join #SplitedAssets On #BookDepreciationEnMasseSetupDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE BookDepreciationEnMasseSetupDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM BookDepreciationEnMasseSetupDetails JOIN #BookDepreciationEnMasseSetupDetailsTemp ON BookDepreciationEnMasseSetupDetails.Id = #BookDepreciationEnMasseSetupDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Sundry Details
SET @TableName = 'SundryDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO SundryDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM SundryDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = SundryDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #SundryDetailsTemp;'
EXEC(@InsertQuery)
--Update Sundry Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #SundryDetailsTemp join #SplitedAssets On #SundryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #SundryDetailsTemp join #SplitedAssets On #SundryDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE SundryDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM SundryDetails JOIN #SundryDetailsTemp ON SundryDetails.Id = #SundryDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Lien Collaterals
SET @TableName = 'LienCollaterals';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO LienCollaterals AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM LienCollaterals
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = LienCollaterals.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #LienCollateralsTemp;'
EXEC(@InsertQuery)
--Update Lien Collaterals
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #LienCollateralsTemp join #SplitedAssets On #LienCollateralsTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE LienCollaterals SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM LienCollaterals JOIN #LienCollateralsTemp ON LienCollaterals.Id = #LienCollateralsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Sundry Recurring Payment Details
SET @TableName = 'SundryRecurringPaymentDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO SundryRecurringPaymentDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM SundryRecurringPaymentDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = SundryRecurringPaymentDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #SundryRecurringPaymentDetailsTemp;'
EXEC(@InsertQuery)
--Update Sundry Recurring Payment Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #SundryRecurringPaymentDetailsTemp join #SplitedAssets On #SundryRecurringPaymentDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #SundryRecurringPaymentDetailsTemp join #SplitedAssets On #SundryRecurringPaymentDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE SundryRecurringPaymentDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM SundryRecurringPaymentDetails JOIN #SundryRecurringPaymentDetailsTemp ON SundryRecurringPaymentDetails.Id = #SundryRecurringPaymentDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Assumption Assets
SET @TableName = 'AssumptionAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssumptionAssets AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssumptionAssets
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssumptionAssets.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssumptionAssetTemp;'
EXEC(@InsertQuery)
--Update Assumption Assets
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #AssumptionAssetTemp join #SplitedAssets On #AssumptionAssetTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssumptionAssets SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssumptionAssets JOIN #AssumptionAssetTemp ON AssumptionAssets.Id = #AssumptionAssetTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- UDFs
SET @TableName = 'UDFs';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO UDFs AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM UDFs
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = UDFs.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #UDFsTemp;'
EXEC(@InsertQuery)
--Update UDFs
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #UDFsTemp join #SplitedAssets On #UDFsTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE UDFs SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM UDFs JOIN #UDFsTemp ON UDFs.Id = #UDFsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Write Down Asset Details
SET @TableName = 'WriteDownAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO WriteDownAssetDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM WriteDownAssetDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = WriteDownAssetDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #WriteDownAssetDetailsTemp;'
EXEC(@InsertQuery)
--Update Write Down Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #WriteDownAssetDetailsTemp join #SplitedAssets On #WriteDownAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #WriteDownAssetDetailsTemp join #SplitedAssets On #WriteDownAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE WriteDownAssetDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM WriteDownAssetDetails JOIN #WriteDownAssetDetailsTemp ON WriteDownAssetDetails.Id = #WriteDownAssetDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Lease Amendment Impairment Asset Details
SET @TableName = 'LeaseAmendmentImpairmentAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO LeaseAmendmentImpairmentAssetDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM LeaseAmendmentImpairmentAssetDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = LeaseAmendmentImpairmentAssetDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #LeaseAmendmentImpairmentAssetDetailsTemp;'
EXEC(@InsertQuery)
--Update Lease Amendment Impairment Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset , @JobInstanceId from #LeaseAmendmentImpairmentAssetDetailsTemp join #SplitedAssets On #LeaseAmendmentImpairmentAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #LeaseAmendmentImpairmentAssetDetailsTemp join #SplitedAssets On #LeaseAmendmentImpairmentAssetDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE LeaseAmendmentImpairmentAssetDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM LeaseAmendmentImpairmentAssetDetails JOIN #LeaseAmendmentImpairmentAssetDetailsTemp ON LeaseAmendmentImpairmentAssetDetails.Id = #LeaseAmendmentImpairmentAssetDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Lease Asset Payment Schedules
SET @TableName = 'LeaseAssetPaymentSchedules';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO LeaseAssetPaymentSchedules AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM LeaseAssetPaymentSchedules
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = LeaseAssetPaymentSchedules.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #LeaseAssetPaymentSchedulesTemp;'
EXEC(@InsertQuery)
--Update Lease Amendment Impairment Asset Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #LeaseAssetPaymentSchedulesTemp join #SplitedAssets On #LeaseAssetPaymentSchedulesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #LeaseAssetPaymentSchedulesTemp join #SplitedAssets On #LeaseAssetPaymentSchedulesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE LeaseAssetPaymentSchedules SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM LeaseAssetPaymentSchedules JOIN #LeaseAssetPaymentSchedulesTemp ON LeaseAssetPaymentSchedules.Id = #LeaseAssetPaymentSchedulesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Tax Dep Entities
SET @TableName = 'TaxDepEntities';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO TaxDepEntities AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId , FeatureAsset FROM TaxDepEntities
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = TaxDepEntities.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #TaxDepEntitiesTemp;'
EXEC(@InsertQuery)
--Update Tax Dep Entities
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #TaxDepEntitiesTemp join #SplitedAssets On #TaxDepEntitiesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #TaxDepEntitiesTemp join #SplitedAssets On #TaxDepEntitiesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE TaxDepEntities SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM TaxDepEntities JOIN #TaxDepEntitiesTemp ON TaxDepEntities.Id = #TaxDepEntitiesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Tax Dep Amortizations
SET @TableName = 'TaxDepAmortizations';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[TaxDepEntityId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[TaxDepEntityId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO TaxDepAmortizations AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #TaxDepEntitiesTemp.NewId , FeatureAsset FROM TaxDepAmortizations
JOIN #TaxDepEntitiesTemp on TaxDepAmortizations.TaxDepEntityId = #TaxDepEntitiesTemp.OldId WHERE #TaxDepEntitiesTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  TaxDepEntityId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #TaxDepAmortizationsTemp;'
EXEC(@InsertQuery)
--Update Tax Dep Amortizations
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #TaxDepAmortizationsTemp join #SplitedAssets On #TaxDepAmortizationsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #TaxDepAmortizationsTemp join #SplitedAssets On #TaxDepAmortizationsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE TaxDepAmortizations SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM TaxDepAmortizations JOIN #TaxDepAmortizationsTemp ON TaxDepAmortizations.Id = #TaxDepAmortizationsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Tax Dep Amortization Details
SET @TableName = 'TaxDepAmortizationDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[TaxDepAmortizationId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[TaxDepAmortizationId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO TaxDepAmortizationDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #TaxDepAmortizationsTemp.NewId FROM TaxDepAmortizationDetails
JOIN #TaxDepAmortizationsTemp on TaxDepAmortizationDetails.TaxDepAmortizationId = #TaxDepAmortizationsTemp.OldId WHERE #TaxDepAmortizationsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  TaxDepAmortizationId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #TaxDepAmortizationDetailsTemp;'
EXEC(@InsertQuery)
--Update Tax Dep Amortization Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #TaxDepAmortizationDetailsTemp join #SplitedAssets On #TaxDepAmortizationDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1 , @JobInstanceId from #TaxDepAmortizationDetailsTemp join #SplitedAssets On #TaxDepAmortizationDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE TaxDepAmortizationDetails SET IsAdjustmentEntry = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM TaxDepAmortizationDetails JOIN #TaxDepAmortizationDetailsTemp ON TaxDepAmortizationDetails.Id = #TaxDepAmortizationDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN   -- Tax Dep Entity En-Masse Update Details
SET @TableName = 'TaxDepEntityEnMasseUpdateDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO TaxDepEntityEnMasseUpdateDetails AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM TaxDepEntityEnMasseUpdateDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = TaxDepEntityEnMasseUpdateDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #TaxDepEntityEnMasseUpdateDetailsTemp;'
EXEC(@InsertQuery)
--Update Tax Dep Entity En-Masse Update Details
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #TaxDepEntityEnMasseUpdateDetailsTemp join #SplitedAssets On #TaxDepEntityEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #TaxDepEntityEnMasseUpdateDetailsTemp join #SplitedAssets On #TaxDepEntityEnMasseUpdateDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE TaxDepEntityEnMasseUpdateDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM TaxDepEntityEnMasseUpdateDetails JOIN #TaxDepEntityEnMasseUpdateDetailsTemp ON TaxDepEntityEnMasseUpdateDetails.Id = #TaxDepEntityEnMasseUpdateDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
END
BEGIN -- Payable Invoices
BEGIN -- Payable Invoice Assets
SET @TableName = 'PayableInvoiceAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO PayableInvoiceAssets AS T1
USING (SELECT Id, NewAssetId, OldAssetId,FeatureAsset, ' + @ColumnList + ' FROM PayableInvoiceAssets
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = PayableInvoiceAssets.AssetId Where #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', AssetId , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0, S1.Id, Inserted.Id, S1.OldAssetId, Inserted.AssetId , S1.PayableInvoiceId ,  S1.FeatureAsset Into #PayableInvoiceAssetsTemp;';
EXEC(@InsertQuery)
--Update Payable Invoice Assets
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #PayableInvoiceAssetsTemp join #SplitedAssets On #PayableInvoiceAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #PayableInvoiceAssetsTemp join #SplitedAssets On #PayableInvoiceAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update PayableInvoiceAssets Set IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' From  PayableInvoiceAssets
JOIN #PayableInvoiceAssetsTemp On #PayableInvoiceAssetsTemp.OldId = PayableInvoiceAssets.Id; '
END
SET @UpdateQuery = @UpdateQuery + '
;With CTE_RowNum As
(
Select NewAssetId, ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewAssetId) AS [RowNum] FROM #PayableInvoiceAssetsTemp
)
Update #PayableInvoiceAssetsTemp Set #PayableInvoiceAssetsTemp.RowNum = CTE_RowNum.RowNum From #PayableInvoiceAssetsTemp
JOIN CTE_RowNum ON CTE_RowNum.NewAssetId = #PayableInvoiceAssetsTemp.NewAssetId;
';
EXEC(@UpdateQuery)
END
BEGIN -- Payable Invoice Deposit Assets
SET @TableName = 'PayableInvoiceDepositAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[DepositAssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[PayableInvoiceId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[DepositAssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[PayableInvoiceId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');


SET @InsertQuery = 'MERGE INTO PayableInvoiceDepositAssets AS T1
USING (SELECT Id, #PayableInvoiceAssetsTemp.NewId, #SplitedAssets.NewAssetId,PayableInvoiceDepositAssets.PayableInvoiceId, ' + @ColumnList + ' FROM PayableInvoiceDepositAssets
JOIN #PayableInvoiceAssetsTemp On #PayableInvoiceAssetsTemp.OldId = PayableInvoiceDepositAssets.DepositAssetId
JOIN #SplitedAssets On #SplitedAssets.NewAssetId = #PayableInvoiceAssetsTemp.NewAssetId  WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', DepositAssetId , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0, S1.Id, Inserted.Id , S1.NewAssetId Into #PayableInvoiceDepositAssetsTemp;';
EXEC(@InsertQuery)
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #PayableInvoiceDepositAssetsTemp join #SplitedAssets On #PayableInvoiceDepositAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #PayableInvoiceDepositAssetsTemp join #SplitedAssets On #PayableInvoiceDepositAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update PayableInvoiceDepositAssets Set IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' From  PayableInvoiceDepositAssets
JOIN #PayableInvoiceDepositAssetsTemp On #PayableInvoiceDepositAssetsTemp.OldId = PayableInvoiceDepositAssets.Id; '
END
SET @UpdateQuery = @UpdateQuery + '
;With CTE_RowNum As
(
Select NewId, ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewId) AS [RowNum] FROM #PayableInvoiceDepositAssetsTemp
)
Update #PayableInvoiceDepositAssetsTemp Set #PayableInvoiceDepositAssetsTemp.RowNum = CTE_RowNum.RowNum From #PayableInvoiceDepositAssetsTemp
JOIN CTE_RowNum ON CTE_RowNum.NewId = #PayableInvoiceDepositAssetsTemp.NewId;
';
Exec(@UpdateQuery)
END
BEGIN -- Payable Invoice Deposit TakeDown Assets
SET @TableName = 'PayableInvoiceDepositTakeDownAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[NegativeDepositAssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[NegativeDepositAssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO PayableInvoiceDepositTakeDownAssets AS T1
USING (SELECT Id, #PayableInvoiceAssetsTemp.NewId,#SplitedAssets.NewAssetId, ' + @ColumnList + ' FROM PayableInvoiceDepositTakeDownAssets
JOIN #PayableInvoiceAssetsTemp On #PayableInvoiceAssetsTemp.OldId = PayableInvoiceDepositTakeDownAssets.NegativeDepositAssetId
JOIN #SplitedAssets On #SplitedAssets.NewAssetId = #PayableInvoiceAssetsTemp.NewAssetId
AND #SplitedAssets.OldAssetId = #PayableInvoiceAssetsTemp.OldAssetId
WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', NegativeDepositAssetId , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT S1.Id, Inserted.Id, Inserted.PayableInvoiceDepositAssetId, Inserted.TakeDownAssetId, S1.NewAssetId Into #PayableInvoiceNegativeTakedownAssetsTemp;';
EXEC(@InsertQuery)
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset , @JobInstanceId from #PayableInvoiceNegativeTakedownAssetsTemp join #SplitedAssets On #PayableInvoiceNegativeTakedownAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #PayableInvoiceNegativeTakedownAssetsTemp join #SplitedAssets On #PayableInvoiceNegativeTakedownAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateQuery = '
;With CTE_DepositAssets As
(
Select ROW_NUMBER() OVER (PARTITION BY OldTakeDownAssetId,PayableInvoiceDepositAssetId ORDER BY PayableInvoiceDepositAssetId) AS [RowNum], PayableInvoiceDepositTakeDownAssets.Id, PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId
From PayableInvoiceDepositTakeDownAssets
JOIN #PayableInvoiceNegativeTakedownAssetsTemp On #PayableInvoiceNegativeTakedownAssetsTemp.NewId = PayableInvoiceDepositTakeDownAssets.Id
)
UPDATE PayableInvoiceDepositTakeDownAssets SET PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId = #PayableInvoiceDepositAssetsTemp.NewId
FROM PayableInvoiceDepositTakeDownAssets
JOIN CTE_DepositAssets On CTE_DepositAssets.Id = PayableInvoiceDepositTakeDownAssets.id
AND CTE_DepositAssets.PayableInvoiceDepositAssetId = PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId
JOIN #PayableInvoiceDepositAssetsTemp  On #PayableInvoiceDepositAssetsTemp.OldId = PayableInvoiceDepositTakeDownAssets.PayableInvoiceDepositAssetId
AND #PayableInvoiceDepositAssetsTemp.RowNum = CTE_DepositAssets.RowNum';
SET @UpdateQuery = @UpdateQuery + '
;With CTE_TakeDown As
(
Select ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewId) AS [RowNum], PayableInvoiceDepositTakeDownAssets.Id, PayableInvoiceDepositTakeDownAssets.TakeDownAssetId, PayableInvoiceDepositAssetId From PayableInvoiceDepositTakeDownAssets
JOIN #PayableInvoiceNegativeTakedownAssetsTemp On #PayableInvoiceNegativeTakedownAssetsTemp.NewId = PayableInvoiceDepositTakeDownAssets.Id
)
UPDATE PayableInvoiceDepositTakeDownAssets SET PayableInvoiceDepositTakeDownAssets.TakeDownAssetId = NegativeTakeDown.NewId
FROM PayableInvoiceDepositTakeDownAssets
JOIN CTE_TakeDown On CTE_TakeDown.Id = PayableInvoiceDepositTakeDownAssets.Id
AND CTE_TakeDown.TakeDownAssetId = PayableInvoiceDepositTakeDownAssets.TakeDownAssetId
JOIN #PayableInvoiceAssetsTemp NegativeTakeDown On NegativeTakeDown.OldId = PayableInvoiceDepositTakeDownAssets.TakeDownAssetId
AND NegativeTakeDown.RowNum = CTE_TakeDown.RowNum;';
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = @UpdateQuery + dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'Update PayableInvoiceDepositTakeDownAssets Set IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' From  PayableInvoiceDepositTakeDownAssets
JOIN #PayableInvoiceNegativeTakedownAssetsTemp On #PayableInvoiceNegativeTakedownAssetsTemp.OldId = PayableInvoiceDepositTakeDownAssets.Id; '
END
EXEC(@UpdateQuery)
END
BEGIN -- Payable Invoice Other Costs
SET @TableName = 'PayableInvoiceOtherCosts';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetFeatureId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetFeatureId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');


SET @InsertQuery = 'MERGE INTO PayableInvoiceOtherCosts AS Target
USING(Select ' + @ColumnList + ',Id , NewAssetId , OldAssetId , NewId , FeatureAsset  From PayableInvoiceOtherCosts
JOIN #AssetFeaturesTemp on #AssetFeaturesTemp.OldId = PayableInvoiceothercosts.AssetFeatureId Where #AssetFeaturesTemp.FeatureAsset = 0) AS Source ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' +@ColumnList + ',AssetId , AssetFeatureId , CreatedById , CreatedTime ) VALUES (' + @ColumnList +',NewAssetId , NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + ''')
OUTPUT  Inserted.Id, Source.Id, Source.NewAssetId, Source.OldAssetId , Source.FeatureAsset INTO #PayableInvoiceOtherCostsTemp;'
EXEC(@InsertQuery)
-- Updating Records in Payable Invoice Other Costs
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #PayableInvoiceOtherCostsTemp join #SplitedAssets On #PayableInvoiceOtherCostsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #PayableInvoiceOtherCostsTemp join #SplitedAssets On #PayableInvoiceOtherCostsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE PayableInvoiceOtherCosts SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM PayableInvoiceOtherCosts JOIN #PayableInvoiceOtherCostsTemp ON PayableInvoiceOtherCosts.Id = #PayableInvoiceOtherCostsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN -- Payable Invoice Other Cost Details
SET @TableName = 'PayableInvoiceOtherCostDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[PayableInvoiceAssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[PayableInvoiceAssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SELECT DISTINCT(PayableInvoiceId) INTO #PayableInvoiceIdTemp FROM #PayableInvoiceAssetsTemp

INSERT INTO #AllocationMethodDetails 
SELECT PayableInvoiceOtherCosts.Id AS 'OtherCostId'
FROM PayableInvoiceOtherCosts 
JOIN #PayableInvoiceIdTemp ON PayableInvoiceOtherCosts.PayableInvoiceId = #PayableInvoiceIdTemp.PayableInvoiceId
WHERE PayableInvoiceOtherCosts.AllocationMethod = 'Specific'

SET @InsertQuery = 'MERGE INTO PayableInvoiceOtherCostDetails AS T1
USING (SELECT Id,payableInvAsset.NewId,  #SplitedAssets.NewAssetId,  #SplitedAssets.OldAssetId, #SplitedAssets.FeatureAsset, ' + @ColumnList + ' FROM PayableInvoiceOtherCostDetails
JOIN #PayableInvoiceAssetsTemp payableInvAsset ON PayableInvoiceOtherCostDetails.PayableInvoiceAssetId = payableInvAsset.OldId
JOIN #SplitedAssets On #SplitedAssets.NewAssetId = payableInvAsset.NewAssetId 
JOIN #AllocationMethodDetails ON PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId = #AllocationMethodDetails.OtherCostId
WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ',PayableInvoiceAssetId ,CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ' ,NewId,' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0, S1.Id, Inserted.Id,S1.NewAssetId,S1.OldAssetId Into #PayableInvoiceOtherCostDetailsTemp;';

EXEC(@InsertQuery)

-- Updating Records in Payable Invoice Other Costs
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #PayableInvoiceOtherCostDetailsTemp join #SplitedAssets On #PayableInvoiceOtherCostDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #PayableInvoiceOtherCostDetailsTemp join #SplitedAssets On #PayableInvoiceOtherCostDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE PayableInvoiceOtherCostDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM PayableInvoiceOtherCostDetails JOIN #PayableInvoiceOtherCostDetailsTemp ON PayableInvoiceOtherCostDetails.Id = #PayableInvoiceOtherCostDetailsTemp.OldId'
END
SET @UpdateQuery = @UpdateQuery + '
;With CTE_RowNum As
(
SELECT NewAssetId, ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewAssetId) AS [RowNum] FROM #PayableInvoiceOtherCostDetailsTemp
)
UPDATE #PayableInvoiceOtherCostDetailsTemp Set #PayableInvoiceOtherCostDetailsTemp.RowNum = CTE_RowNum.RowNum FROM #PayableInvoiceOtherCostDetailsTemp
JOIN CTE_RowNum ON CTE_RowNum.NewAssetId = #PayableInvoiceOtherCostDetailsTemp.NewAssetId;
';
EXEC(@UpdateQuery)
END
BEGIN
INSERT INTO #PayableInvoiceTemp
SELECT Distinct PayableInvoiceId  From #PayableInvoiceAssetsTemp
INSERT INTO #PayableInvoiceCountTemp
SELECT PayableInvoices.Id , COUNT(*) FROM PayableInvoices
JOIN PayableInvoiceAssets ON PayableInvoices.Id = PayableInvoiceAssets.PayableInvoiceId
JOIN #PayableInvoiceTemp ON PayableInvoices.Id = #PayableInvoiceTemp.Id
WHERE PayableInvoiceAssets.IsActive = 1
GROUP BY PayableInvoices.Id
SET @UpdateQuery = 'UPDATE PayableInvoices
SET NumberOfAssets = #PayableInvoiceCountTemp.AssetCount
FROM PayableInvoices JOIN #PayableInvoiceCountTemp ON PayableInvoices.Id = #PayableInvoiceCountTemp.Id'
EXEC(@UpdateQuery)
END
END
BEGIN--- Receivable Details Section Begin
BEGIN   --  Receivable Details
SET @TableName = 'ReceivableDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceivableDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId, FeatureAsset FROM ReceivableDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = ReceivableDetails.AssetId WHERE #SplitedAssets.FeatureAsset = 0 AND ReceivableDetails.IsActive=1) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,AssetId , CreatedById , CreatedTime  ) VALUES
(
' + @ColumnList + ' ,NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId, S1.FeatureAsset Into #ReceivableDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceivableDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID, 1  from #ReceivableDetailsTemp join #SplitedAssets On #ReceivableDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, '+@JobInstanceIdInString +'  from #ReceivableDetailsTemp join #SplitedAssets On #ReceivableDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
-- Update Receivable Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceivableDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ReceivableDetails JOIN #ReceivableDetailsTemp ON ReceivableDetails.Id = #ReceivableDetailsTemp.OldId;'
END
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceivableDetails SET AdjustmentBasisReceivableDetailId = AdjustmentDetail.NewId FROM ReceivableDetails JOIN #ReceivableDetailsTemp AS AdjustmentDetail ON ReceivableDetails.AdjustmentBasisReceivableDetailId = AdjustmentDetail.OldId AND ReceivableDetails.AssetId = AdjustmentDetail.NewAssetID;'
EXEC(@UpdateQuery)

END	-- Receivable Details



BEGIN   --  One Time ACH Receivable Details
SET @TableName = 'OneTimeACHReceivableDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableDetailId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableDetailId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO OneTimeACHReceivableDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #ReceivableDetailsTemp.NewId,#ReceivableDetailsTemp.FeatureAsset 
FROM (SELECT OneTimeACHReceivableDetails.* FROM OneTimeACHReceivableDetails 
JOIN OneTimeACHSchedules ON OneTimeACHReceivableDetails.OneTimeACHScheduleId = OneTimeACHSchedules.Id 
JOIN OneTimeAches ON OneTimeAches.Id = OneTimeACHSchedules.OneTimeACHId
WHERE OneTimeAches.Status =''Pending'' AND OneTimeACHReceivableDetails.IsActive = 1 AND OneTimeACHSchedules.IsActive = 1) As OneTimeACHReceivableDetails
JOIN #ReceivableDetailsTemp on OneTimeACHReceivableDetails.ReceivableDetailId = #ReceivableDetailsTemp.OldId WHERE #ReceivableDetailsTemp.FeatureAsset = 0
) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableDetailId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId,S1.FeatureAsset Into #OneTimeACHReceivableDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #OneTimeACHReceivableDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID,1  from #OneTimeACHReceivableDetailsTemp join #SplitedAssets On #OneTimeACHReceivableDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, '+@JobInstanceIdInString +'  from #OneTimeACHReceivableDetailsTemp join #SplitedAssets On #OneTimeACHReceivableDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update One Time ACH Receivable Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE OneTimeACHReceivableDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM OneTimeACHReceivableDetails JOIN #OneTimeACHReceivableDetailsTemp ON OneTimeACHReceivableDetails.Id = #OneTimeACHReceivableDetailsTemp.OldId;'
END
EXEC(@UpdateQuery)
END -- One Time ACH Receivable Details



BEGIN   --  Receipt Application Receivable Details
SET @TableName = 'ReceiptApplicationReceivableDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableDetailId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableDetailId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceiptApplicationReceivableDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #ReceivableDetailsTemp.NewId,#ReceivableDetailsTemp.FeatureAsset FROM ReceiptApplicationReceivableDetails
JOIN #ReceivableDetailsTemp on ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetailsTemp.OldId WHERE #ReceivableDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableDetailId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId, S1.PayableId,S1.FeatureAsset Into #ReceiptApplicationReceivableDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceiptApplicationReceivableDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID,OldPayableId,1  from #ReceiptApplicationReceivableDetailsTemp join #SplitedAssets On #ReceiptApplicationReceivableDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, '+@JobInstanceIdInString +'  from #ReceiptApplicationReceivableDetailsTemp join #SplitedAssets On #ReceiptApplicationReceivableDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receipt Application Receivable Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceiptApplicationReceivableDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ReceiptApplicationReceivableDetails JOIN #ReceiptApplicationReceivableDetailsTemp ON ReceiptApplicationReceivableDetails.Id = #ReceiptApplicationReceivableDetailsTemp.OldId;'
END
EXEC(@UpdateQuery)
END -- Receipt Application Receivable Details
BEGIN   --  Receivable Invoice Details
SET @TableName = 'ReceivableInvoiceDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableDetailId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableDetailId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceivableInvoiceDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #ReceivableDetailsTemp.NewId FROM ReceivableInvoiceDetails
JOIN #ReceivableDetailsTemp on ReceivableInvoiceDetails.ReceivableDetailId = #ReceivableDetailsTemp.OldId WHERE #ReceivableDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableDetailId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #ReceivableInvoiceDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceivableInvoiceDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #ReceivableInvoiceDetailsTemp join #SplitedAssets On #ReceivableInvoiceDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,'+@JobInstanceIdInString +'  from #ReceivableInvoiceDetailsTemp join #SplitedAssets On #ReceivableInvoiceDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receivable Invoice Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceivableInvoiceDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ReceivableInvoiceDetails JOIN #ReceivableInvoiceDetailsTemp ON ReceivableInvoiceDetails.Id = #ReceivableInvoiceDetailsTemp.OldId;'
END
EXEC(@UpdateQuery)
END -- Receivable Invoice Details
BEGIN   --  Receivable Tax Details
SET @TableName = 'ReceivableTaxDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableDetailId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetLocationId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableDetailId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetLocationId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceivableTaxDetails AS T1
USING (SELECT '+ @ColumnList + ', ReceivableTaxDetails.Id  , #ReceivableDetailsTemp.NewAssetId , #ReceivableDetailsTemp.OldAssetId , #ReceivableDetailsTemp.NewId , #AssetLocationsTemp.NewId AS NewAssetLocationId, #ReceivableDetailsTemp.FeatureAsset FROM ReceivableTaxDetails
JOIN #ReceivableDetailsTemp on ReceivableTaxDetails.ReceivableDetailId = #ReceivableDetailsTemp.OldId
LEFT JOIN #AssetLocationsTemp ON ReceivableTaxDetails.AssetLocationId = #AssetLocationsTemp.OldId AND #ReceivableDetailsTemp.NewAssetID = #AssetLocationsTemp.NewAssetID WHERE #ReceivableDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableDetailId , AssetId , AssetLocationId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , NewAssetId , NewAssetLocationId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId,S1.FeatureAsset Into #ReceivableTaxDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceivableTaxDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID,1  from #ReceivableTaxDetailsTemp join #SplitedAssets On #ReceivableTaxDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,'+@JobInstanceIdInString +'  from #ReceivableTaxDetailsTemp join #SplitedAssets On #ReceivableTaxDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receivable Tax Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceivableTaxDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ReceivableTaxDetails JOIN #ReceivableTaxDetailsTemp ON ReceivableTaxDetails.Id = #ReceivableTaxDetailsTemp.OldId;'
END
EXEC(@UpdateQuery)
END -- Receivable Tax Details
BEGIN   --  Receivable Tax Reversal Details
SET @TableName = 'ReceivableTaxReversalDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[Id],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[AssetLocationId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[Id]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[AssetLocationId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceivableTaxReversalDetails AS T1
USING (SELECT '+ @ColumnList + ', ReceivableTaxReversalDetails.Id  , #ReceivableTaxDetailsTemp.NewAssetId , #ReceivableTaxDetailsTemp.OldAssetId , #ReceivableTaxDetailsTemp.NewId, #AssetLocationsTemp.NewId AS NewAssetLocationId FROM ReceivableTaxReversalDetails
JOIN #ReceivableTaxDetailsTemp on ReceivableTaxReversalDetails.Id = #ReceivableTaxDetailsTemp.OldId
LEFT JOIN #AssetLocationsTemp ON ReceivableTaxReversalDetails.AssetLocationId = #AssetLocationsTemp.OldId AND #ReceivableTaxDetailsTemp.NewAssetID = #AssetLocationsTemp.NewAssetID WHERE #ReceivableTaxDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  Id , AssetId , AssetLocationId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , NewAssetId , NewAssetLocationId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #ReceivableTaxReversalDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceivableTaxReversalDetailsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #ReceivableTaxReversalDetailsTemp join #SplitedAssets On #ReceivableTaxReversalDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,'+@JobInstanceIdInString +'  from #ReceivableTaxReversalDetailsTemp join #SplitedAssets On #ReceivableTaxReversalDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receivable Tax Reversal Details
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
EXEC(@UpdateQuery)
END -- Receivable Tax Reversal Details
BEGIN   --  Receivable Tax Impositions
SET @TableName = 'ReceivableTaxImpositions';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableTaxDetailId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableTaxDetailId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceivableTaxImpositions AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #ReceivableTaxDetailsTemp.NewId,#ReceivableTaxDetailsTemp.FeatureAsset FROM ReceivableTaxImpositions
JOIN #ReceivableTaxDetailsTemp on ReceivableTaxImpositions.ReceivableTaxDetailId = #ReceivableTaxDetailsTemp.OldId WHERE #ReceivableTaxDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableTaxDetailId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId,S1.FeatureAsset Into #ReceivableTaxImpositionsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceivableTaxImpositionsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID,1  from #ReceivableTaxImpositionsTemp join #SplitedAssets On #ReceivableTaxImpositionsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,'+@JobInstanceIdInString +'  from #ReceivableTaxImpositionsTemp join #SplitedAssets On #ReceivableTaxImpositionsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receivable Tax Impositions
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,1);
EXEC(@UpdateQuery)
END -- Receivable Tax Impositions
BEGIN   --  Receipt Application Receivable Tax Impositions
SET @TableName = 'ReceiptApplicationReceivableTaxImpositions';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[ReceivableTaxImpositionId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[ReceivableTaxImpositionId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO ReceiptApplicationReceivableTaxImpositions AS T1
USING (SELECT '+ @ColumnList + ', Id  , NewAssetId , OldAssetId , #ReceivableTaxImpositionsTemp.NewId FROM ReceiptApplicationReceivableTaxImpositions
JOIN #ReceivableTaxImpositionsTemp on ReceiptApplicationReceivableTaxImpositions.ReceivableTaxImpositionId = #ReceivableTaxImpositionsTemp.OldId WHERE #ReceivableTaxImpositionsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' ,  ReceivableTaxImpositionId , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #ReceiptApplicationReceivableTaxImpositionsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #ReceiptApplicationReceivableTaxImpositionsTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #ReceiptApplicationReceivableTaxImpositionsTemp join #SplitedAssets On #ReceiptApplicationReceivableTaxImpositionsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,'+@JobInstanceIdInString +'  from #ReceiptApplicationReceivableTaxImpositionsTemp join #SplitedAssets On #ReceiptApplicationReceivableTaxImpositionsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Receipt Application Receivable Tax Impositions
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceiptApplicationReceivableTaxImpositions SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM ReceiptApplicationReceivableTaxImpositions JOIN #ReceiptApplicationReceivableTaxImpositionsTemp ON ReceiptApplicationReceivableTaxImpositions.Id = #ReceiptApplicationReceivableTaxImpositionsTemp.OldId;'
END
EXEC(@UpdateQuery)

--Latest ReceivableDetail's ReceiptApplicationReceivableDetails Adjustments

DECLARE @AmountAppliedToAdjust DECIMAL(18,2)
DECLARE @TaxAppliedAmountToAdjust DECIMAL(18,2) 
;WITH CTE_RecordToUpdate AS (
 
 SELECT rard.ReceivableDetailId ,Max(rard.Id) [Latest],Sum(rard.AmountApplied_Amount) TotalAmountApplied,Sum(rard.TaxApplied_Amount) TotalTaxApplied
FROM 
ReceiptApplicationReceivableDetails rard  
JOIN #ReceivableDetailsTemp RDT ON  rard.ReceivableDetailId= RDT.NewId
JOIN ReceiptApplications RA  ON rard.ReceiptApplicationId = RA.Id
JOIN Receipts R ON RA.ReceiptId = R.ID
WHERE  R.Status NOT IN ('Inactive','Reversed')
GROUP BY rard.ReceivableDetailId 
)
UPDATE ReceiptApplicationReceivableDetails 
SET  
  @AmountAppliedToAdjust= (ReceivableDetails.Amount_Amount-ReceivableDetails.EffectiveBalance_Amount)-TotalAmountApplied,
  @TaxAppliedAmountToAdjust= CASE WHEN ReceivableTaxDetails.Amount_Amount IS NOT NULL THEN (ReceivableTaxDetails.Amount_Amount-ReceivableTaxDetails.EffectiveBalance_Amount)-TotalTaxApplied ELSE 0.00 END,
  PreviousAmountApplied_Amount = CASE WHEN PreviousAmountApplied_Amount<>0 THEN PreviousAmountApplied_Amount+@AmountAppliedToAdjust ELSE 
  PreviousAmountApplied_Amount END,
  PreviousTaxApplied_Amount = CASE WHEN PreviousTaxApplied_Amount<>0 THEN PreviousTaxApplied_Amount+@TaxAppliedAmountToAdjust ELSE 
  PreviousTaxApplied_Amount END,
  BookAmountApplied_Amount = CASE WHEN BookAmountApplied_Amount<>0 THEN BookAmountApplied_Amount+@AmountAppliedToAdjust ELSE 
  BookAmountApplied_Amount END,
  RecoveryAmount_Amount = CASE WHEN RecoveryAmount_Amount<>0 THEN RecoveryAmount_Amount+@AmountAppliedToAdjust ELSE 
  RecoveryAmount_Amount END,
  GainAmount_Amount = CASE WHEN GainAmount_Amount<>0 THEN GainAmount_Amount+@AmountAppliedToAdjust ELSE 
  GainAmount_Amount END,
  AmountApplied_Amount=AmountApplied_Amount+@AmountAppliedToAdjust,
  TaxApplied_Amount=TaxApplied_Amount+@TaxAppliedAmountToAdjust
FROM CTE_RecordToUpdate 
JOIN ReceiptApplicationReceivableDetails  ON CTE_RecordToUpdate.Latest=ReceiptApplicationReceivableDetails.Id
JOIN ReceivableDetails ON CTE_RecordToUpdate.ReceivableDetailId=ReceivableDetails.Id AND ReceivableDetails.IsActive=1
LEFT JOIN ReceivableTaxDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive=1



--Last ReceivableTaxImposition Amount Adjustment
 
;WITH CTE_RecordToUpdate AS (  

SELECT rti.ReceivableTaxDetailId ,Max(rti.Id) [Latest],SUM(rti.Amount_Amount) TotalAmount,Sum(rti.Balance_Amount) TotalBalance,Sum(rti.EffectiveBalance_Amount) TotalEffectiveBalance   
FROM ReceivableTaxImpositions rti   
JOIN #ReceivableTaxDetailsTemp RTDT ON rti.ReceivableTaxDetailId=RTDT.NewId  
GROUP BY rti.ReceivableTaxDetailId  
)    
UPDATE ReceivableTaxImpositions   
SET     
    ReceivableTaxImpositions.Amount_Amount=ReceivableTaxDetails.Amount_Amount-TotalAmount+ReceivableTaxImpositions.Amount_Amount,
   ReceivableTaxImpositions.Balance_Amount=ReceivableTaxDetails.Balance_Amount-TotalBalance+ReceivableTaxImpositions.Balance_Amount,
   ReceivableTaxImpositions.EffectiveBalance_Amount=ReceivableTaxDetails.EffectiveBalance_Amount-TotalEffectiveBalance+ReceivableTaxImpositions.EffectiveBalance_Amount
FROM CTE_RecordToUpdate   
JOIN ReceivableTaxImpositions ON CTE_RecordToUpdate.Latest=ReceivableTaxImpositions.Id AND ReceivableTaxImpositions.IsActive=1  
JOIN ReceivableTaxDetails ON CTE_RecordToUpdate.ReceivableTaxDetailId=ReceivableTaxDetails.Id AND ReceivableTaxDetails.IsActive=1


-- Latest ReceivableTaxImpositon's ReceiptApplicationReceivableTaxImpositions Tax Amount Posted Adjustment

;WITH CTE_RecordToUpdate AS (
 
SELECT rarti.ReceivableTaxImpositionId ,Max(rarti.Id) [Latest],SUM(rarti.AmountPosted_Amount) TotalAmountPosted
FROM  
ReceivableTaxImpositions rti
JOIN ReceiptApplicationReceivableTaxImpositions rarti ON rarti.ReceivableTaxImpositionId=rti.Id 
JOIN #ReceivableTaxDetailsTemp RTDT ON  rti.ReceivableTaxDetailId= RTDT.NewId
JOIN ReceiptApplications RA  ON rarti.ReceiptApplicationId = RA.Id
JOIN Receipts R on RA.ReceiptId = R.ID
WHERE  R.Status NOT IN ('Inactive','Reversed')
GROUP BY rarti.ReceivableTaxImpositionId 
) 
UPDATE ReceiptApplicationReceivableTaxImpositions 
SET
AmountPosted_Amount=  (ReceivableTaxImpositions.Amount_Amount-ReceivableTaxImpositions.EffectiveBalance_Amount)-CTE_RecordToUpdate.TotalAmountPosted+AmountPosted_Amount
FROM CTE_RecordToUpdate 
JOIN ReceiptApplicationReceivableTaxImpositions ON CTE_RecordToUpdate.Latest=ReceiptApplicationReceivableTaxImpositions.Id
JOIN ReceivableTaxImpositions ON CTE_RecordToUpdate.ReceivableTaxImpositionId=ReceivableTaxImpositions.Id AND ReceivableTaxImpositions.IsActive=1


END -- Receipt Application Receivable Tax Impositions
END
BEGIN -- Payables Part
BEGIN -- Payables
SET @TableName = 'Payables';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[SourceId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[SourceId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO Payables AS T1
USING (SELECT Id, NewAssetId,NewId, OldAssetId,FeatureAsset, ' + @ColumnList + ' FROM Payables
JOIN #PayableInvoiceAssetsTemp ON Payables.SourceId = #PayableInvoiceAssetsTemp.OldId AND Payables.SourceTable = ''PayableInvoiceAsset'' Where FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', SourceId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #PayablesTemp;';
SET @InsertQuery = @InsertQuery +  'MERGE INTO Payables AS T1
USING (SELECT Id, NewAssetId,NewId, OldAssetId,FeatureAsset, ' + @ColumnList + ' FROM Payables
JOIN #PayableInvoiceOtherCostsTemp ON Payables.SourceId = #PayableInvoiceOtherCostsTemp.OldId AND Payables.SourceTable = ''PayableInvoiceOtherCost'' Where FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', SourceId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #PayablesTemp;';
SET @InsertQuery = @InsertQuery +  'MERGE INTO Payables AS T1
USING (SELECT Id, NewAssetId, OldAssetId, SourceId,#ReceiptApplicationReceivableDetailsTemp.FeatureAsset, ' + @ColumnList + ' FROM Payables
JOIN #ReceiptApplicationReceivableDetailsTemp ON Payables.Id = #ReceiptApplicationReceivableDetailsTemp.OldPayableId AND Payables.SourceTable = ''SundryPayable'' WHERE #ReceiptApplicationReceivableDetailsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', SourceId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', SourceId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId, S1.FeatureAsset Into #PayablesTemp;';
EXEC(@InsertQuery)
-- Updating Payables
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset,@JobInstanceId from #PayablesTemp join #SplitedAssets On #PayablesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1,@JobInstanceId from #PayablesTemp join #SplitedAssets On #PayablesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
SET @UpdateQuery = @UpdateQuery + 'UPDATE ReceiptApplicationReceivableDetails
SET PayableId = #PayablesTemp.NewId
FROM ReceiptApplicationReceivableDetails
INNER JOIN #ReceiptApplicationReceivableDetailsTemp ON ReceiptApplicationReceivableDetails.Id = #ReceiptApplicationReceivableDetailsTemp.NewId
INNER JOIN #PayablesTemp ON #ReceiptApplicationReceivableDetailsTemp.OldPayableId = #PayablesTemp.OldId AND #ReceiptApplicationReceivableDetailsTemp.NewAssetID = #PayablesTemp.NewAssetID;'
EXEC(@UpdateQuery)
END
BEGIN -- Treasury Payable Details
SET @TableName = 'TreasuryPayableDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[PayableId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[PayableId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO TreasuryPayableDetails AS T1
USING (SELECT Id, NewAssetId, OldAssetId, NewId, ' + @ColumnList + ' FROM TreasuryPayableDetails
JOIN #PayablesTemp ON TreasuryPayableDetails.PayableId = #PayablesTemp.OldId
Where FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', PayableId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId Into #TreasuryPayableDetailsTemp;';
EXEC(@InsertQuery)
-- Updating Payables
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #TreasuryPayableDetailsTemp join #SplitedAssets On #TreasuryPayableDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #TreasuryPayableDetailsTemp join #SplitedAssets On #TreasuryPayableDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE TreasuryPayableDetails SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM TreasuryPayableDetails JOIN #TreasuryPayableDetailsTemp ON TreasuryPayableDetails.Id = #TreasuryPayableDetailsTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN -- Disbursement Request Payables
SET @TableName = 'DisbursementRequestPayables';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[PayableId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[PayableId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

DELETE FROM #PayablesTemp WHERE NewAssetId in (SELECT #PayablesTemp.NewAssetId FROM #PayablesTemp 
JOIN #SplitedAssets ON #PayablesTemp.NewAssetID = #SplitedAssets.NewAssetId
WHERE #SplitedAssets.Prorate = 0 )
SET @InsertQuery = 'MERGE INTO DisbursementRequestPayables AS T1
USING (SELECT Id, NewAssetId, OldAssetId,NewId,FeatureAsset, ' + @ColumnList + ' FROM DisbursementRequestPayables
JOIN #PayablesTemp ON DisbursementRequestPayables.PayableId = #PayablesTemp.OldId
Where FeatureAsset = 0 ) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', PayableId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId , S1.FeatureAsset Into #DisbursementRequestPayablesTemp;';
EXEC(@InsertQuery)
-- Updating Disbursement Request Payables
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #DisbursementRequestPayablesTemp join #SplitedAssets On #DisbursementRequestPayablesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT DISTINCT OldId, OldId ,0 , 1, @JobInstanceId from #DisbursementRequestPayablesTemp join #SplitedAssets On #DisbursementRequestPayablesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE DisbursementRequestPayables SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM DisbursementRequestPayables JOIN #DisbursementRequestPayablesTemp ON DisbursementRequestPayables.Id = #DisbursementRequestPayablesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN -- Disbursement Request Payees
SET @TableName = 'DisbursementRequestPayees';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[DisbursementRequestPayableId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[DisbursementRequestPayableId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO DisbursementRequestPayees AS T1
USING (SELECT Id, NewAssetId, OldAssetId,NewId,FeatureAsset, ' + @ColumnList + ' FROM DisbursementRequestPayees
JOIN #DisbursementRequestPayablesTemp ON DisbursementRequestPayees.DisbursementRequestPayableId = #DisbursementRequestPayablesTemp.OldId
Where FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', DisbursementRequestPayableId  , CreatedById , CreatedTime )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId Into #DisbursementRequestPayeesTemp;';
EXEC(@InsertQuery)
-- Updating Disbursement Request Payees
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #DisbursementRequestPayeesTemp join #SplitedAssets On #DisbursementRequestPayeesTemp.NewAssetID = #SplitedAssets.NewAssetID
IF @SplitByType = 'AssetSplitFeature'
BEGIN
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT distinct OldId, OldId ,Prorate , 1 , @JobInstanceId from #DisbursementRequestPayeesTemp join #SplitedAssets On #DisbursementRequestPayeesTemp.NewAssetID = #SplitedAssets.NewAssetID
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE DisbursementRequestPayees SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM DisbursementRequestPayees JOIN #DisbursementRequestPayeesTemp ON DisbursementRequestPayees.Id = #DisbursementRequestPayeesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN -- Payable GL Journals
SET @TableName = 'PayableGLJournals';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[PayableId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[PayableId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO PayableGLJournals AS T1
USING (SELECT Id, NewAssetId, OldAssetId,NewId, ' + @ColumnList + ' FROM PayableGLJournals
JOIN #PayablesTemp ON PayableGLJournals.PayableId = #PayablesTemp.OldId
Where FeatureAsset = 0 ) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', PayableId , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id ,S1.Id, S1.NewAssetId, S1.OldAssetId Into #PayableGLJournalsTemp;';
EXEC(@InsertQuery)
-- Updating Payable GL Journals
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, @JobInstanceId  from #PayableGLJournalsTemp join #SplitedAssets On #PayableGLJournalsTemp.NewAssetID = #SplitedAssets.NewAssetID
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
EXEC(@UpdateQuery)
END
END
BEGIN -- Lease Assets
SET @TableName = 'LeaseAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

BEGIN -- Lease Assets Associated with Assets
SET @InsertQuery = 'MERGE INTO LeaseAssets AS T1
USING (SELECT Id, NewAssetId, OldAssetId,Prorate, #SplitedAssets.IsLastAsset,' + @ColumnList + ' FROM LeaseAssets
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = LeaseAssets.AssetId WHERE #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', AssetId , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0,Inserted.Id,S1.Id,Inserted.AssetId,S1.OldAssetId,S1.IsLastAsset,S1.CapitalizedForId,0,S1.Prorate Into #LeaseAssetsTemp;';
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #LeaseAssetsTemp
SELECT DISTINCT 0,OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID,1,#LeaseAssetsTemp.OldCapitalizedForId,1,#SplitedAssets.Prorate  from #LeaseAssetsTemp join #SplitedAssets On #LeaseAssetsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select NewId, OldId, Prorate, IsLast,'+@JobInstanceIdInString +'  From #LeaseAssetsTemp';
EXEC(@InsertQuery)
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
-- Updating Capitalized For Id
SET @UpdateQuery = @UpdateQuery + ' UPDATE LeaseAssets set CapitalizedForId = #LeaseAssetsTemp.NewId FROM LeaseAssets
JOIN #LeaseAssetsTemp ON LeaseAssets.CapitalizedForId = #LeaseAssetsTemp.OldId and LeaseAssets.AssetId = #LeaseAssetsTemp.NewAssetId;'
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update LeaseAssets Set IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' From  LeaseAssets
JOIN #LeaseAssetsTemp On #LeaseAssetsTemp.OldId = LeaseAssets.Id; '
END
SET @UpdateQuery = @UpdateQuery + '
;With CTE_RowNum As
(
Select NewId, ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewId) AS [RowNum] FROM #LeaseAssetsTemp
)
Update #LeaseAssetsTemp Set #LeaseAssetsTemp.RowNumber = CTE_RowNum.RowNum From #LeaseAssetsTemp
JOIN CTE_RowNum ON CTE_RowNum.NewId = #LeaseAssetsTemp.NewId;
';
EXEC(@UpdateQuery)
END
BEGIN -- LeaseAssets for which Soft Assets are not created
SET @InsertQuery ='MERGE INTO LeaseAssets AS T1
USING(SELECT Id, #LeaseAssetsTemp.Prorate, #LeaseAssetsTemp.IsLast,' + @ColumnList + 'FROM LeaseAssets
JOIN #LeaseAssetsTemp ON LeaseAssets.CapitalizedForId = #LeaseAssetsTemp.OldId AND LeaseAssets.AssetId IS NULL AND #LeaseAssetsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' +@ColumnList + ' , AssetID  , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NULL , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0,Inserted.Id,S1.Id, NULL,NULL,S1.IsLast,S1.CapitalizedForId,0,S1.Prorate INTO #LeaseAssetsTemp;';
SET @InsertQuery = @InsertQuery +  'MERGE INTO LeaseAssets AS T1
USING(SELECT Id, #LeaseAssetsTemp.Prorate, #LeaseAssetsTemp.IsLast,' + @ColumnList + 'FROM LeaseAssets
JOIN #LeaseAssetsTemp ON LeaseAssets.CapitalizedForId = #LeaseAssetsTemp.OldId AND LeaseAssets.AssetId IS NULL AND #LeaseAssetsTemp.FeatureAsset = 0
AND LeaseAssets.Id NOT IN (SELECT OldId FROM #LeaseAssetsTemp UNION SELECT NewId FROM #LeaseAssetsTemp)) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' +@ColumnList + ' , AssetID  , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ' , NULL , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT 0,Inserted.Id,S1.Id, NULL,NULL,S1.IsLast,S1.CapitalizedForId,0,S1.Prorate INTO #LeaseAssetsTemp;';
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #LeaseAssetsTemp SELECT 0, Id, Id, NULL,NULL, 1, CapitalizedForId, 1,1 FROM LeaseAssets
JOIN #LeaseAssetsTemp ON LeaseAssets.CapitalizedForId = #LeaseAssetsTemp.OldId AND LeaseAssets.AssetId IS NULL AND #LeaseAssetsTemp.FeatureAsset = 1;'
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select NewId, OldId, Prorate, IsLast,'+@JobInstanceIdInString +'  From #LeaseAssetsTemp WHERE NewAssetId IS NULL';
EXEC(@InsertQuery)
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
;WITH CTE_LeaseLastAsset
AS
(
SELECT MAX(NewId) as NewLeaseAssetId FROM #LeaseAssetsTemp GROUP BY #LeaseAssetsTemp.OldId
)
UPDATE #LeaseAssetsTemp SET IsLast = 1 FROM #LeaseAssetsTemp
JOIN CTE_LeaseLastAsset ON #LeaseAssetsTemp.NewId = CTE_LeaseLastAsset.NewLeaseAssetId
END
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
SET @UpdateQuery = @UpdateQuery + '
;With CTE_RowNum As
(
Select NewId, ROW_NUMBER() OVER (PARTITION BY OldId ORDER BY NewId) AS [RowNum] FROM #LeaseAssetsTemp
)
Update #LeaseAssetsTemp Set #LeaseAssetsTemp.RowNumber = CTE_RowNum.RowNum From #LeaseAssetsTemp
JOIN CTE_RowNum ON CTE_RowNum.NewId = #LeaseAssetsTemp.NewId;
SELECT #LeaseAssetsTemp.NewId as LeaseAssetId ,LT.NewId as CapitalizedForId INTO #CapitalizedLeaseAssetsTemp FROM
#LeaseAssetsTemp
JOIN #LeaseAssetsTemp LT ON #LeaseAssetsTemp.OldCapitalizedForId = LT.OldId AND #LeaseAssetsTemp.RowNumber = LT.RowNumber
UPDATE LeaseAssets SET CapitalizedForId = #CapitalizedLeaseAssetsTemp.CapitalizedForId
FROM
LeaseAssets
JOIN #CapitalizedLeaseAssetsTemp ON LeaseAssets.Id = #CapitalizedLeaseAssetsTemp.LeaseAssetId;'
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update LeaseAssets Set IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' From  LeaseAssets
JOIN #LeaseAssetsTemp On #LeaseAssetsTemp.OldId = LeaseAssets.Id; '
END
--- Update Ref Number in Lease Asset ---
SET @UpdateQuery = @UpdateQuery + 'SELECT
LeaseAssets.LeaseFinanceId,LeaseAssets.Id as LeaseAssetId,StatusRank = CASE WHEN Assets.Id IS NOT NULL AND Assets.FinancialType = ''Real'' AND LeaseAssets.CapitalizedForId IS NULL THEN 1
WHEN Assets.Id IS NOT NULL AND Assets.FinancialType = ''Dummy'' AND LeaseAssets.CapitalizedForId IS NULL THEN  2
WHEN LeaseAssets.CapitalizedForId IS NOT NULL AND LeaseAssets.CapitalizationType = ''CapitalizedInterimInterest'' THEN 3
WHEN LeaseAssets.CapitalizedForId IS NOT NULL AND LeaseAssets.CapitalizationType = ''CapitalizedInterimRent'' THEN 4
WHEN LeaseAssets.CapitalizedForId IS NOT NULL AND LeaseAssets.CapitalizationType = ''CapitalizedProgressPayment'' THEN 5
WHEN LeaseAssets.CapitalizedForId IS NOT NULL AND LeaseAssets.CapitalizationType = ''CapitalizedSalesTax'' THEN  6
WHEN Assets.Id IS NOT NULL AND Assets.Id IS NOT NULL AND Assets.FinancialType = ''NegativeReturn'' THEN 7
WHEN Assets.Id IS NOT NULL AND ASsets.FinancialType = ''Placeholder'' THEN 8
WHEN Assets.Id IS NOT NULL AND Assets.FinancialType = ''Deposit'' THEN 9
WHEN Assets.Id IS NOT NULL AND ASsets.FinancialType =''NegativeDeposit'' THEN 10
ELSE 0
END,
MAX(ReferenceNumber) OVER(PARTITION BY LeaseAssets.LeaseFinanceId) as ''MaximumRefNumber''
INTO #LeaseAssetSummary
FROM LeaseAssets
LEFT JOIN Assets ON LeaseAssets.AssetId = Assets.Id
ORDER BY LeaseAssets.LeaseFinanceId,StatusRank
;WITH CTE_RowNumber AS
(
SELECT LeaseFinanceId,LeaseAssetId, MaximumRefNumber + ROW_NUMBER() OVER(PARTITION BY LeaseFinanceId ORDER BY StatusRank,LeaseAssetId) as RefNum FROM
#LeaseAssetSummary
JOIN #LeaseAssetsTemp ON #LeaseAssetSummary.LeaseAssetId = #LeaseAssetsTemp.NewId AND #LeaseAssetsTemp.FeatureAsset = 0
)
UPDATE LeaseAssets SET ReferenceNumber = RefNum
FROM
LeaseAssets
JOIN CTE_RowNumber ON LeaseAssets.Id = CTE_RowNumber.LeaseAssetId
IF OBJECT_ID(''tempdb..#LeaseAssetSummary'') IS NOT NULL
DROP TABLE #LeaseAssetSummary;'
EXEC(@UpdateQuery)
END

BEGIN -- Lease Preclassification Results
SET @TableName = 'LeasePreclassificationResults';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[Id],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[Id]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

 -- Lease Preclassification Results associated with Assets

SET @InsertQuery = 'MERGE INTO LeasePreclassificationResults AS LP1
USING (SELECT '+ @ColumnList + ', Id  , #LeaseAssetsTemp.NewId , #LeaseAssetsTemp.OldId ,#LeaseAssetsTemp.OldAssetId ,#LeaseAssetsTemp.NewAssetId   FROM LeasePreclassificationResults
JOIN #LeaseAssetsTemp On  #LeaseAssetsTemp.OldId = LeasePreclassificationResults.Id AND #LeaseAssetsTemp.FeatureAsset = 0) AS LA1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ', Id , CreatedById , CreatedTime  )VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)
OUTPUT Inserted.Id, LA1.Id, LA1.NewId, LA1.OldId,LA1.NewAssetId, LA1.OldAssetId  Into #LeasePreclassificationResultsTemp;';

IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #LeasePreclassificationResultsTemp
SELECT DISTINCT #LeasePreclassificationResultsTemp.OldId, #LeasePreclassificationResultsTemp.OldId, #LeasePreclassificationResultsTemp.NewLeaseAssetID, #LeasePreclassificationResultsTemp.OldLeaseAssetID ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #LeasePreclassificationResultsTemp join #SplitedAssets On #LeasePreclassificationResultsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;';
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select NewId, OldId, Prorate, IsLastAsset,'+@JobInstanceIdInString +'  From #LeasePreclassificationResultsTemp
JOIN #SplitedAssets On #LeasePreclassificationResultsTemp.NewAssetID = #SplitedAssets.NewAssetID;';
EXEC(@InsertQuery)

    
--Update Record in LeasePreclassificationResults
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
EXEC(@UpdateQuery)

END

BEGIN   --  Pay off assets
SET @TableName = 'Payoffassets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[LeaseAssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[LeaseAssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO Payoffassets AS T1
USING (SELECT '+ @ColumnList + ', Id  , #LeaseAssetsTemp.NewAssetId , #LeaseAssetsTemp.OldAssetId , NewId FROM Payoffassets
JOIN #LeaseAssetsTemp on Payoffassets.LeaseAssetId = #LeaseAssetsTemp.OldId WHERE FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' , LeaseAssetId  , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ',  NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #PayoffAssetsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #PayoffAssetsTemp
SELECT DISTINCT #PayoffAssetsTemp.OldId, #PayoffAssetsTemp.OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #PayoffAssetsTemp join #SplitedAssets On #PayoffAssetsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;';
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select NewId, OldId, Prorate, IsLastAsset,'+@JobInstanceIdInString +'  From #PayoffAssetsTemp
JOIN #SplitedAssets On #PayoffAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID;';
EXEC(@InsertQuery)
--Update Record in Pay off assets
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE Payoffassets SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM Payoffassets JOIN #PayoffassetsTemp ON Payoffassets.Id = #PayoffassetsTemp.OldId'
END
EXEC(@UpdateQuery)
END
END

BEGIN   --  Lease Asset Income Details
SET @TableName = 'LeaseAssetIncomeDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');

SET @InsertQuery = 'MERGE INTO LeaseAssetIncomeDetails AS T1
USING (SELECT '+ @ColumnList + ', Id  , #LeaseAssetsTemp.NewAssetId , #LeaseAssetsTemp.OldAssetId , NewId FROM LeaseAssetIncomeDetails
JOIN #LeaseAssetsTemp on LeaseAssetIncomeDetails.Id = #LeaseAssetsTemp.OldId WHERE FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + ' , Id , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', S1.NewId, ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #LeaseAssetIncomeDetailsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #LeaseAssetIncomeDetailsTemp
SELECT DISTINCT #LeaseAssetIncomeDetailsTemp.OldId, #LeaseAssetIncomeDetailsTemp.OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #LeaseAssetIncomeDetailsTemp join #SplitedAssets On #LeaseAssetIncomeDetailsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;';
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select NewId, OldId, Prorate, IsLastAsset,'+@JobInstanceIdInString +'  From #LeaseAssetIncomeDetailsTemp
JOIN #SplitedAssets On #LeaseAssetIncomeDetailsTemp.NewAssetID = #SplitedAssets.NewAssetID;';
EXEC(@InsertQuery)
--Update Record in Pay off assets
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);

EXEC(@UpdateQuery)
END

BEGIN  -- Asset Float Rate Income
SET @TableName = 'AssetFloatRateIncomes';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetFloatRateIncomes AS T1
USING (SELECT '+ @ColumnList + ', Id , #SplitedAssets.NewAssetId , #SplitedAssets.OldAssetId FROM AssetFloatRateIncomes
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetFloatRateIncomes.AssetId AND AssetFloatRateIncomes.IsActive = 1 AND #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime  ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetFloatRateIncomesTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #AssetFloatRateIncomesTemp
SELECT DISTINCT OldId, OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #LeaseAssetsTemp join #SplitedAssets On #LeaseAssetsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select #AssetFloatRateIncomesTemp.NewId, #AssetFloatRateIncomesTemp.OldId, #SplitedAssets.Prorate, #SplitedAssets.IsLastAsset,'+@JobInstanceIdInString +'  From #AssetFloatRateIncomesTemp
JOIN #SplitedAssets ON #AssetFloatRateIncomesTemp.NewAssetId = #SplitedAssets.NewAssetId';
EXEC(@InsertQuery)
--Update Record in Assets Float Rate Incomes
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
SET @UpdateQuery = @UpdateQuery + 'SELECT
DISTINCT
LFI.LeaseFinanceId,
AssetFloatRateIncomes.Id,
AssetFloatRateIncomes.AssetId,
LFI.IncomeDate,
AssetFloatRateIncomes.CustomerIncomeAmount_Amount,
AssetFloatRateIncomes.CustomerIncomeAccruedAmount_Amount,
AssetFloatRateIncomes.CustomerReceivableAmount_Amount,
LeaseFinanceDetails.IsAdvance AS IsAdvance,
LeasePaymentSchedules.StartDate,
LeasePaymentSchedules.EndDate,
CASE WHEN LFI.IncomeDate = LeasePaymentSchedules.EndDate THEN 1 ELSE 0 END AS ''IsPaymentEndDate'',
MIN (LFI.IncomeDate) OVER(PARTITION BY LeaseFinanceId,AssetFloatRateIncomes.AssetId,LeasePaymentSchedules.EndDate) as ''PaymentStartDate'',
SUM(AssetFloatRateIncomes.CustomerIncomeAmount_Amount) OVER(PARTITION BY LFI.LeaseFinanceId,AssetFloatRateIncomes.AssetId,LeasePaymentSchedules.EndDate ORDER BY LFI.IncomeDate ROWS UNBOUNDED PRECEDING) As ''ComputedCustomerIncomeAccrued'',
SUM (AssetFloatRateIncomes.CustomerIncomeAmount_Amount) OVER (PARTITION BY LFI.LeaseFinanceId, AssetFloatRateIncomes.AssetId,LeasePaymentSchedules.ENdDAte ORDER BY LFI.IncomeDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) As ''CustomerIncomeAccruedInAdvance''
INTO #AssetFloatRateIncomeSummary
FROM
AssetFloatRateIncomes
JOIN #AssetFloatRateIncomesTemp ON AssetFloatRateIncomes.Id = #AssetFloatRateIncomesTemp.NewId
JOIN LeaseFloatRateIncomes LFI ON AssetFloatRateIncomes.LeaseFloatRateIncomeId = LFI.Id
JOIN LeaseFinanceDetails ON LFI.LeaseFinanceId = LeaseFinanceDetails.Id
JOIN LeasePaymentSchedules ON LFI.IncomeDate >= LeasePaymentSchedules.StartDate AND LFI.IncomeDate <= LeasePaymentSchedules.EndDate
AND LeasePaymentSchedules.LeaseFinanceDetailId = LeaseFinanceDetails.Id AND LeasePaymentSchedules.IsActive = 1
WHERE
AssetFloatRateIncomes.IsActive = 1
ORDER BY LeaseFinanceId,AssetId,IncomeDate
UPDATE AssetFloatRateIncomes SET CustomerIncomeAccruedAmount_Amount = 0, CustomerReceivableAmount_Amount = 0
FROM
AssetFloatRateIncomes
JOIN #AssetFloatRateIncomeSummary ON AssetFloatRateIncomes.Id = #AssetFloatRateIncomeSummary.Id
UPDATE AssetFloatRateIncomes SET CustomerIncomeAccruedAmount_Amount = CASE WHEN #AssetFloatRateIncomeSummary.IsPaymentEndDate = 0 THEN #AssetFloatRateIncomeSummary.ComputedCustomerIncomeAccrued ELSE 0 END,
CustomerReceivableAmount_Amount = CASE WHEN #AssetFloatRateIncomeSummary.IsAdvance = 1 AND #AssetFloatRateIncomeSummary.IncomeDate = #AssetFloatRateIncomeSummary.PaymentStartDate THEN #AssetFloatRateIncomeSummary.CustomerIncomeAccruedInAdvance
WHEN #AssetFloatRateIncomeSummary.IsAdvance = 0 AND #AssetFloatRateIncomeSummary.IsPaymentEndDate = 1 THEN #AssetFloatRateIncomeSummary.ComputedCustomerIncomeAccrued
ELSE 0 END
FROM
AssetFloatRateIncomes
JOIN #AssetFloatRateIncomeSummary ON AssetFloatRateIncomes.Id = #AssetFloatRateIncomeSummary.Id
IF OBJECT_ID(''tempdb..#AssetFloatRateIncomeSummary'') IS NOT NULL
DROP TABLE #AssetFloatRateIncomeSummary;'
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetFloatRateIncomes SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetFloatRateIncomes JOIN #AssetFloatRateIncomesTemp ON AssetFloatRateIncomes.Id = #AssetFloatRateIncomesTemp.OldId'
END
EXEC(@UpdateQuery)
END
BEGIN  -- Asset Income Schedules
SET @TableName = 'AssetIncomeSchedules';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[AssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[AssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO AssetIncomeSchedules AS T1
USING (SELECT '+ @ColumnList + ', Id , NewAssetId , OldAssetId FROM AssetIncomeSchedules
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetIncomeSchedules.AssetId AND #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , AssetId , CreatedById , CreatedTime  ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #AssetIncomeSchedulesTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + ' INSERT INTO #AssetIncomeSchedulesTemp
SELECT DISTINCT #AssetIncomeSchedulesTemp.OldId, #AssetIncomeSchedulesTemp.OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID from #AssetIncomeSchedulesTemp join #SplitedAssets On #AssetIncomeSchedulesTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + ' DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId) Select #AssetIncomeSchedulesTemp.NewId, #AssetIncomeSchedulesTemp.OldId, #SplitedAssets.Prorate, #SplitedAssets.IsLastAsset, '+@JobInstanceIdInString +'  From #AssetIncomeSchedulesTemp
JOIN #SplitedAssets ON #AssetIncomeSchedulesTemp.NewAssetId = #SplitedAssets.NewAssetId';
EXEC(@InsertQuery)
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName, @UpdateColumnName, @UserId , @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE AssetIncomeSchedules SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM AssetIncomeSchedules JOIN #AssetIncomeSchedulesTemp ON AssetIncomeSchedules.Id = #AssetIncomeSchedulesTemp.OldId'
END
EXEC(@UpdateQuery)


DECLARE @ReaccrualPaymentDate DATETIME;
DECLARE @ReaccrualDate DATETIME;
DECLARE @NonAccrualDate DATETIME;
DECLARE @NBVAsofReaccrualDate DECIMAL(18,2);
DECLARE @SplitCount INT;
SELECT @SplitCount = COUNT(*) FROM #SplitedAssets

-- Fill Lease Amendments
Select distinct AmendmentDate,CASE WHEN AmendmentType = 'Rebook' THEN 1 ELSE AmendmentAtInception END [AmendmentAtInception], AmendmentType, LeaseFinances.id [AmendmentId], 
	LeaseAssetIncomeDetails.Income_Amount, LeaseAssets.NBV_Amount, LeaseAssets.BookedResidual_Amount, LeaseAssets.CustomerGuaranteedResidual_Amount, 
	LeaseAssets.ThirdPartyGuaranteedResidual_Amount, LeaseAssetIncomeDetails.ResidualIncome_Amount, IsCurrent, AssetId, LeaseAssets.IsLeaseAsset, 
	LeaseAssets.FMV_Amount, LeaseAssets.CapitalizedIDC_Amount, LeaseAssets.ETCAdjustmentAmount_Amount,LeaseAssetIncomeDetails.FinanceIncome_Amount,
	LeaseAssetIncomeDetails.FinanceResidualIncome_Amount
into #LeaseAmendments From LeaseAmendments
Join LeaseFinances On LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId And (ApprovalStatus = 'Approved' or ApprovalStatus = 'InsuranceFollowup')
Join LeaseAssets On LeaseAssets.LeaseFinanceId = LeaseFinances.Id
Join LeaseAssetIncomeDetails on LeaseAssets.Id = LeaseAssetIncomeDetails.Id
Where LeaseAssets.AssetId in (SELECT distinct NewAssetId FROM #AssetIncomeSchedulesTemp) And LeaseAmendmentStatus = 'Approved' And AmendmentType IN ('Restructure','Rebook','ResidualImpairment','GLTransfer')
Order By AmendmentDate

DECLARE @HasNoAmendment Bit;
SET @HasNoAmendment = 1;
If EXISTS(Select * From #LeaseAmendments)
BEGIN
SET @HasNoAmendment = 0;
END

-- Add booking entry to lease amendments for all new assets 
Insert Into #LeaseAmendments
Select distinct null,0 [AmendmentAtInception],'Booking', LeaseFinances.Id [AmendmentId], LeaseAssetIncomeDetails.Income_Amount, LeaseAssets.NBV_Amount, 
	LeaseAssets.BookedResidual_Amount, LeaseAssets.CustomerGuaranteedResidual_Amount, LeaseAssets.ThirdPartyGuaranteedResidual_Amount,  LeaseAssetIncomeDetails.ResidualIncome_Amount, 
	@HasNoAmendment, AssetId, LeaseAssets.IsLeaseAsset, LeaseAssets.FMV_Amount, LeaseAssets.CapitalizedIDC_Amount, LeaseAssets.ETCAdjustmentAmount_Amount,
	LeaseAssetIncomeDetails.FinanceIncome_Amount,LeaseAssetIncomeDetails.FinanceResidualIncome_Amount 
From LeaseAssets
Join LeaseFinances On LeaseAssets.LeaseFinanceId = LeaseFinances.Id
join LeaseAssetIncomeDetails on LeaseAssets.Id = LeaseAssetIncomeDetails.Id
left join LeaseAmendments ON LeaseFinances.Id = LeaseAmendments.CurrentLeaseFinanceId
Where LeaseAmendments.AmendmentType IS NULL AND LeaseAssets.AssetId in (SELECT distinct NewAssetId FROM #AssetIncomeSchedulesTemp) And BookingStatus = 'Commenced' And (ApprovalStatus = 'Approved' or ApprovalStatus = 'InsuranceFollowup') Order By LeaseFinances.Id Asc

-- Delete the booking record if any AmendmentAtInception Exist
If EXISTS(Select * From #LeaseAmendments Where AmendmentAtInception = 1)
BEGIN
Delete From #LeaseAmendments Where AmendmentType = 'Booking'
Update #LeaseAmendments Set AmendmentType = 'Booking' Where AmendmentAtInception = 1
END
--Add Current Lease Asset Info
Select distinct LeaseAssetIncomeDetails.Income_Amount, LeaseAssetIncomeDetails.ResidualIncome_Amount, AssetId,
	LeaseAssetIncomeDetails.FinanceIncome_Amount, LeaseAssetIncomeDetails.FinanceResidualIncome_Amount,LeaseAssetIncomeDetails.LeaseIncome_Amount 
into #CurrentLeaseAssetsInfo From LeaseAssets
Join LeaseFinances On LeaseAssets.LeaseFinanceId = LeaseFinances.Id
Join LeaseAssetIncomeDetails on LeaseAssets.Id = LeaseAssetIncomeDetails.Id
Where LeaseAssets.AssetId in (SELECT distinct NewAssetId FROM #AssetIncomeSchedulesTemp) 
And LeaseFinances.IsCurrent = 1


-- To Find payment end date & month end date record
SELECT EndDate INTO #PaymentEndDates FROM LeasepaymentSchedules WHERE IsActive = 1 AND LeaseFinanceDetailId = @LeaseFinanceId

-- To Find  maturity payment start date & end date
SELECT StartDate,EndDate INTO #MaturityPayment FROM LeasepaymentSchedules WHERE IsActive = 1 AND LeaseFinanceDetailId = @LeaseFinanceId AND EndDate = @ContractMaturityDate AND PaymentType='FixedTerm'

SELECT @NonAccrualDate = NonAccrualDate FROM Contracts WHERE Id = @ContractIdToConsider

-- Fill reaccrual date and suspended income amount for reaccrual contracts
SELECT Top 1 @ReaccrualDate = ReAccrualDate, @NBVAsofReaccrualDate = NBV_Amount - SuspendedIncome_Amount FROM ReAccrualContracts WHERE ContractId = @ContractIdToConsider AND IsActive = 1
Order By ReAccrualDate Desc

IF @NBVAsofReaccrualDate <> 0
BEGIN
Update #SplitedAssets Set ReaccrualNBV = @NBVAsofReaccrualDate * Prorate
Update #SplitedAssets Set ReaccrualNBV = @NBVAsofReaccrualDate - (Select SUM(ReaccrualNBV) From #SplitedAssets Where IsLastAsset = 0) Where IsLastAsset = 1
END


DECLARE @SkipAmortRoundingRoutine Bit
SET @SkipAmortRoundingRoutine = 0

IF (@LeaseContractType ='Operating' AND NOT EXISTS(SELECT * FROM #LeaseAmendments WHERE IsCurrent = 1 AND IsLeaseAsset = 0))
	SET @SkipAmortRoundingRoutine = 1

IF(@SyndicationType = 'FullSale')
BEGIN
	DECLARE @IsSyndicationAtInception Bit
	SET @IsSyndicationAtInception= 0
	Select @IsSyndicationAtInception = AmendmentAtInception From LeaseAmendments Where CurrentLeaseFinanceId = @LeaseFinanceId And LeaseAmendmentStatus = 'Approved' And AmendmentType = 'Syndication'
	IF @IsSyndicationAtInception = 0
		SET @SkipAmortRoundingRoutine = 1
END

IF @SkipAmortRoundingRoutine = 0 
BEGIN

DECLARE @AssetIdToModify BIGINT;

IF @LeaseContractType = 'Operating'
BEGIN
Insert Into #NewlyCreatedAssetIds SELECT DISTINCT NewAssetId FROM #AssetIncomeSchedulesTemp JOIN #LeaseAmendments ON #AssetIncomeSchedulesTemp.NewAssetId = #LeaseAmendments.AssetId WHERE IsCurrent = 1 AND #LeaseAmendments.IsLeaseAsset = 0;
END
ELSE
BEGIN
Insert Into #NewlyCreatedAssetIds SELECT DISTINCT NewAssetId FROM #AssetIncomeSchedulesTemp;
END

DECLARE AssetCur CURSOR FOR SELECT NewAssetId FROM #NewlyCreatedAssetIds;
OPEN AssetCur
FETCH NEXT FROM AssetCur
INTO @AssetIdToModify
WHILE @@FETCH_STATUS = 0
BEGIN	
	DECLARE @IncomeId BIGINT;
	DECLARE @Income DECIMAL(18,2);
	DECLARE @Payment DECIMAL(18,2);
	DECLARE @IncomeDate DATETIME;
	DECLARE @ResidualIncome DECIMAL(18,2);
	DECLARE @IsMonthEnd BIT;
	DECLARE @IsPaymentEndDate BIT;
	DECLARE @PreviousPaymentFound DECIMAL(18,2);
	DECLARE @PreviousIncomeAmount DECIMAL(18,2);
	DECLARE @PreviousIncomeBalance DECIMAL(18,2);
	DECLARE @PreviousEndNBV DECIMAL(18,2);	
	DECLARE @PreviousResidualIncome DECIMAL(18,2);
	DECLARE @LastPaymentDate DATETIME;
	DECLARE @CalculatedBeginNBV DECIMAL(18,2) = 0.0;
	DECLARE @TotalIncomeBalance DECIMAL(18,2) = 0.0;
	DECLARE @IncomeAmount DECIMAL(18,2) = 0.0;
	DECLARE @LessorRisk DECIMAL(18,2) = 0.0;
	DECLARE @CalculatedResidualIncomeBalance DECIMAL(18,2) = 0.0;
	DECLARE @ResidualIncomeAssetAmount DECIMAL(18,2) = 0.0;
	DECLARE @RunningResidualIncomeAmountForPayment DECIMAL(18,2) = 0.0;
	DECLARE @RunningResidualIncomeAmountForAmendment DECIMAL(18,2) = 0.0;	
	DECLARE @IsAmendmentRecord BIT;
	DECLARE @RunningIncomeAmount DECIMAL(18,2);
	DECLARE @TotalAssetIncomeAmount DECIMAL(18,2);
	DECLARE @TotalAssetResidualIncomeAmount DECIMAL(18,2);
	DECLARE @PreviousDeferredSellingProfitIncomeBalance DECIMAL(18,2);
	DECLARE @AssetIncomeScheduleId BIGINT;
	DECLARE @FMV DECIMAL(18,2) = 0.0;
	DECLARE @NBV DECIMAL(18,2) = 0.0;
	DECLARE @IncomeRecoveredThroughBlendedItem DECIMAL(18,2) =0.0;
	DECLARE @ResidualIncomeRecoveredThroughBlendedItem DECIMAL(18,2) =0.0;
	DECLARE @TotalFinanceIncomeBalance DECIMAL(18,2) = 0.0;
	DECLARE @ExpectedFinanceIncome DECIMAL(18,2) = 0.0;
	DECLARE @ActualFinanceIncome DECIMAL(18,2);
	DECLARE @FinanceIncomeRecoveredThroughBlendedItem DECIMAL(18,2) =0.0;
	DECLARE @ExpectedFinanceResidualIncome DECIMAL(18,2) =0.0;
	DECLARE @ActualFinanceResidualIncome DECIMAL(18,2) = 0.0;
	DECLARE @FinanceResidualIncomeRecoveredThroughBlendedItem DECIMAL(18,2) =0.0;
	DECLARE @FinanceIncome DECIMAL(18,2) =0.0;
	DECLARE @FinanceResidualIncome DECIMAL(18,2) =0.0;
	DECLARE @PreviousFinanceIncomeBalance DECIMAL(18,2)=0.0;
	DECLARE @CalculatedFinanceResidualIncomeBalance DECIMAL(18,2)=0.0;
	DECLARE @LessorRiskForFinanceAsset DECIMAL(18,2) = 0.0;
	DECLARE @PreviousFinanceIncome DECIMAL(18,2)=0.0;
	DECLARE @PreviousFinanceResidualIncome DECIMAL(18,2) =0.0;
	DECLARE @RunningFinanceResidualIncomeAmountForPayment DECIMAL(18,2)=0.0;
	DECLARE @RunningFinanceResidualIncomeAmountForAmendment DECIMAL(18,2)=0.0;
	DECLARE @RunningFinanceIncomeAmount DECIMAL(18,2) = 0.0;
	DECLARE @CalculatedFinanceBeginNBV DECIMAL(18,2) = 0.0;	
	DECLARE @PreviousFinanceEndNBV DECIMAL(18,2)=0.0;
	DECLARE @FinancePaymentAmount DECIMAL(18,2)=0.0;
	DECLARE @TotalLastPaymentIncome DECIMAL(18,2)=0.0;
	
	DECLARE @IsLeaseAsset BIT;
	-- Set values from booking record to start asset income schedule	
	Select @TotalIncomeBalance = Income_Amount,
	@TotalFinanceIncomeBalance = FinanceIncome_Amount,
		   @CalculatedBeginNBV = CASE WHEN (@ContractType ='DirectFinance' OR @ContractType = 'SalesType' OR @ContractType = 'IFRSFinanceLease' OR @ContractType = 'ConditionalSales')
								  AND @ContractAccountingStandard !='ASC840_IAS17' AND IsLeaseAsset=1
                                THEN FMV_Amount + CapitalizedIDC_Amount-ETCAdjustmentAmount_Amount
						        ELSE NBV_Amount -ETCAdjustmentAmount_Amount
						        END,@NBV = NBV_Amount,
		   @FMV=FMV_Amount, @LessorRisk = (BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)) 
	 ,@CalculatedResidualIncomeBalance = @LessorRisk - ResidualIncome_Amount,@IsLeaseAsset = IsLeaseAsset From #LeaseAmendments Where (AmendmentType = 'Booking'	or AmendmentType = 'Rebook' or AmendmentType = 'Restructure' or (AmendmentAtInception = 1 and IsCurrent = 1)) AND AssetId = @AssetIdToModify order by AmendmentId

	 SELECT @LessorRiskForFinanceAsset =(BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)),
	 @CalculatedFinanceResidualIncomeBalance = @LessorRiskForFinanceAsset - FinanceResidualIncome_Amount, @CalculatedFinanceBeginNBV =NBV_Amount -ETCAdjustmentAmount_Amount   From #LeaseAmendments Where (AmendmentType = 'Booking'	or AmendmentType = 'Rebook' or AmendmentType = 'Restructure' or (AmendmentAtInception = 1 and IsCurrent = 1)) AND AssetId = @AssetIdToModify  AND IsLeaseAsset=0 order by AmendmentId
	
	SELECT @LessorRisk = (BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)) FROM #LeaseAmendments WHERE IsCurrent = 1 and AssetId = @AssetIdToModify

	SELECT @ResidualIncomeAssetAmount = ResidualIncome_Amount, @IncomeAmount = Income_Amount,@ExpectedFinanceIncome = FinanceIncome_Amount,@ExpectedFinanceResidualIncome = FinanceResidualIncome_Amount FROM #CurrentLeaseAssetsInfo WHERE AssetId = @AssetIdToModify

	-- Fill #IncomeSchedules
	SELECT AIS.Id, AIS.Payment_Amount, AIS.Income_Amount, AIS.IncomeAccrued_Amount, AIS.IncomeBalance_Amount, AIS.BeginNetBookValue_Amount, AIS.EndNetBookValue_Amount, @IsAdvance [IsAdvance], LIS.IncomeDate, AIS.ResidualIncomeBalance_Amount, AIS.ResidualIncome_Amount,LIS.IsNonAccrual,AIS.FinanceIncomeBalance_Amount,AIS.FinanceIncome_Amount,AIS.FinanceResidualIncome_Amount,AIS.FinanceResidualIncomeBalance_Amount,AIS.FinanceIncomeAccrued_Amount,AIS.FinanceBeginNetBookValue_Amount
	,AIS.FinanceEndNetBookValue_Amount,AIS.FinancePayment_Amount,AIS.LeaseRentalIncome_Amount,AIS.LeaseResidualIncome_Amount,AIS.LeaseIncome_Amount,AIS.LeaseBeginNetBookValue_Amount,AIS.LeaseEndNetBookValue_Amount, Case When IncomeDate = (DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, LIS.IncomeDate) + 1, 0))) Then 1 Else 0 End [IsMonthEnd], AIS.DeferredSellingProfitIncome_Amount , AIS.DeferredSellingProfitIncomeBalance_Amount INTO #IncomeSchedules
		FROM LeaseIncomeSchedules LIS JOIN AssetIncomeSchedules AIS ON LIS.Id = AIS.LeaseIncomeScheduleId
		JOIN LeaseFinances LF ON LIS.LeaseFinanceId = LF.Id AND LF.ContractId = @ContractIdToConsider
		WHERE AIS.AssetId = @AssetIdToModify AND LIS.IncomeDate <= @ContractMaturityDate AND AIS.IsActive = 1 AND LIS.IsSchedule = 1 AND LIS.IsLessorOwned = 1
	
	IF @ReaccrualDate IS NOT NULL
	BEGIN
		IF @IsBlendedRecoveryMethod = 1 
		BEGIN
			SELECT @IncomeRecoveredThroughBlendedItem = SUM(Income_Amount),@ResidualIncomeRecoveredThroughBlendedItem = SUM(ResidualIncome_Amount),@FinanceIncomeRecoveredThroughBlendedItem = SUM(FinanceIncome_Amount),@FinanceResidualIncomeRecoveredThroughBlendedItem = SUM(FinanceResidualIncome_Amount) FROM #IncomeSchedules WHERE IsNonAccrual =1 and (@NonAccrualDate is null or IncomeDate < @NonAccrualDate)
			SELECT @IncomeAmount = @IncomeAmount - @IncomeRecoveredThroughBlendedItem	
			SELECT @ResidualIncomeAssetAmount = @ResidualIncomeAssetAmount - @ResidualIncomeRecoveredThroughBlendedItem
			SELECT @ExpectedFinanceIncome = @ExpectedFinanceIncome - @FinanceIncomeRecoveredThroughBlendedItem
			SELECT @ExpectedFinanceResidualIncome = @ExpectedFinanceResidualIncome - @FinanceResidualIncomeRecoveredThroughBlendedItem

		END
		IF @NonAccrualDate IS NOT NULL
		BEGIN
			SELECT @TotalAssetIncomeAmount = SUM(Income_Amount), @TotalAssetResidualIncomeAmount = SUM(ResidualIncome_Amount),@ActualFinanceIncome = SUM(FinanceIncome_Amount),@ActualFinanceResidualIncome = SUM(FinanceResidualIncome_Amount) FROM #IncomeSchedules WHERE ((IsNonAccrual = 0 AND IncomeDate < @NonAccrualDate) OR (IsNonAccrual =1 and IncomeDate >= @NonAccrualDate))
		END
		ELSE
		BEGIN
			SELECT @TotalAssetIncomeAmount = SUM(Income_Amount),@TotalAssetResidualIncomeAmount = SUM(ResidualIncome_Amount),@ActualFinanceIncome = SUM(FinanceIncome_Amount),@ActualFinanceResidualIncome = SUM(FinanceResidualIncome_Amount)  FROM #IncomeSchedules WHERE IsNonAccrual =0
		END		
	END
	ELSE
	BEGIN
		 SELECT @TotalAssetIncomeAmount = SUM(Income_Amount),@TotalAssetResidualIncomeAmount = SUM(ResidualIncome_Amount),@ActualFinanceIncome = SUM(FinanceIncome_Amount),@ActualFinanceResidualIncome = SUM(FinanceResidualIncome_Amount)  FROM #IncomeSchedules 
	END
	-- Delete the incomes prior to reaccrual date And Set the balance as of reaccrual date
	SELECT TOP 1 @ReaccrualPaymentDate = IncomeDate FROM #IncomeSchedules WHERE @ReaccrualDate <= IncomeDate ORDER BY IncomeDate
	DELETE FROM #IncomeSchedules WHERE IncomeDate < @ReaccrualPaymentDate
	IF @ReaccrualPaymentDate is not null
	BEGIN

		Select @CalculatedBeginNBV = ReaccrualNBV From #SplitedAssets Where NewAssetId = @AssetIdToModify
		Select @TotalIncomeBalance = ISNULL(LeaseAssetIncomeDetails.Income_Amount, 0.00), @LessorRisk = (BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)) 
		 ,@CalculatedResidualIncomeBalance = @LessorRisk - ISNULL(LeaseAssetIncomeDetails.ResidualIncome_Amount, 0.00), @ResidualIncomeAssetAmount = ISNULL(LeaseAssetIncomeDetails.ResidualIncome_Amount, 0.00), @IncomeAmount = ISNULL(LeaseAssetIncomeDetails.Income_Amount, 0.00)
		 From LeaseAssets
		 LEFT JOIN LeaseAssetIncomeDetails on LeaseAssets.Id = LeaseAssetIncomeDetails.Id 
		 Where AssetId = @AssetIdToModify And IsActive = 1

		 --Set BeginNBV, Income balance and residual income balance values for first asset income schedule record
		UPDATE #IncomeSchedules SET BeginNetBookValue_Amount = @CalculatedBeginNBV, IncomeBalance_Amount = @TotalIncomeBalance - Income_Amount, ResidualIncomeBalance_Amount = @CalculatedResidualIncomeBalance +ResidualIncome_Amount WHERE Id IN (SELECT Top 1 Id FROM #IncomeSchedules ORDER BY IncomeDate) 
	END
    
	--Set BeginNBV, Income balance and residual income balance values for first asset income schedule record
	UPDATE #IncomeSchedules SET BeginNetBookValue_Amount = @CalculatedBeginNBV, IncomeBalance_Amount = @TotalIncomeBalance, FinanceIncomeBalance_Amount =@TotalFinanceIncomeBalance, ResidualIncomeBalance_Amount = @CalculatedResidualIncomeBalance,FinanceBeginNetBookValue_Amount = @CalculatedFinanceBeginNBV WHERE Id IN (SELECT Top 1 Id FROM #IncomeSchedules ORDER BY IncomeDate) AND @ReaccrualPaymentDate IS NULL

	--Adjust last record's income amount and residual income amount
	IF (@IncomeAmount > @TotalAssetIncomeAmount)
	BEGIN		
		UPDATE #IncomeSchedules SET Income_Amount = Income_Amount + (@IncomeAmount - @TotalAssetIncomeAmount) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END
	IF (@TotalAssetIncomeAmount > @IncomeAmount)
	BEGIN
		UPDATE #IncomeSchedules SET Income_Amount = Income_Amount - (@TotalAssetIncomeAmount - @IncomeAmount) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
    END		
	IF (@ExpectedFinanceIncome > @ActualFinanceIncome)
	BEGIN		
		UPDATE #IncomeSchedules SET FinanceIncome_Amount = FinanceIncome_Amount + (@ExpectedFinanceIncome - @ActualFinanceIncome) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END
	IF (@ActualFinanceIncome > @ExpectedFinanceIncome)
	BEGIN
		UPDATE #IncomeSchedules SET FinanceIncome_Amount = FinanceIncome_Amount - (@ActualFinanceIncome - @ExpectedFinanceIncome) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
    END		
	IF (@ExpectedFinanceResidualIncome > @ActualFinanceResidualIncome)
	BEGIN
		UPDATE #IncomeSchedules SET FinanceResidualIncome_Amount = FinanceResidualIncome_Amount + (@ExpectedFinanceResidualIncome - @ActualFinanceResidualIncome) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END
	IF (@ActualFinanceResidualIncome > @ExpectedFinanceResidualIncome)
	BEGIN
	    UPDATE #IncomeSchedules SET FinanceResidualIncome_Amount = FinanceResidualIncome_Amount - (@ActualFinanceResidualIncome - @ExpectedFinanceResidualIncome) 
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END
	IF (@ResidualIncomeAssetAmount > @TotalAssetResidualIncomeAmount)
	BEGIN
		UPDATE #IncomeSchedules SET ResidualIncome_Amount = ResidualIncome_Amount + (@ResidualIncomeAssetAmount - @TotalAssetResidualIncomeAmount)
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END
	IF (@TotalAssetResidualIncomeAmount > @ResidualIncomeAssetAmount)
	BEGIN
		UPDATE #IncomeSchedules SET ResidualIncome_Amount = ResidualIncome_Amount - (@TotalAssetResidualIncomeAmount - @ResidualIncomeAssetAmount)
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
    END
	
	if(@IsLeaseAsset =1)
	BEGIN
	UPDATE #IncomeSchedules SET  LeaseResidualIncome_Amount= ResidualIncome_Amount,LeaseIncome_Amount = Income_Amount
		WHERE Id in (SELECT TOP 1 Id FROM #IncomeSchedules WHERE Income_Amount != 0.0 ORDER BY IncomeDate DESC)
	END


	SET @PreviousFinanceResidualIncome = @CalculatedFinanceResidualIncomeBalance
	SET @PreviousFinanceIncome=0.0

	SET @PreviousPaymentFound = 0
	SET @PreviousIncomeAmount = 0.0
	SET @PreviousIncomeBalance = @TotalIncomeBalance
	SET @PreviousFinanceIncomeBalance = @TotalFinanceIncomeBalance
	SET @PreviousDeferredSellingProfitIncomeBalance = CASE WHEN @FMV > @NBV THEN @FMV - @NBV ELSE 0 END
	SET @PreviousEndNBV = @CalculatedBeginNBV
	SET @PreviousFinanceEndNBV = @CalculatedFinanceBeginNBV
	SET @PreviousResidualIncome = @CalculatedResidualIncomeBalance
	SET @LastPaymentDate = (Select Top 1 IncomeDate From #IncomeSchedules Where Payment_Amount != 0 Order By IncomeDate Desc);
	SET @IsAmendmentRecord = 0
	SET @RunningIncomeAmount = 0.0
	SET @RunningFinanceIncomeAmount =0.0

	IF(@LastPaymentDate IS NULL)
		SET @LastPaymentDate = (Select Top 1 IncomeDate From #IncomeSchedules Order By IncomeDate Desc);

		DECLARE IncomeCur CURSOR
		FOR SELECT Id, Payment_Amount, Income_Amount, IncomeDate, ResidualIncome_Amount, IsMonthEnd,FinanceIncome_Amount,FinanceResidualIncome_Amount,FinancePayment_Amount  FROM #IncomeSchedules ORDER BY IncomeDate
		
		OPEN IncomeCur;

		FETCH NEXT FROM IncomeCur
		INTO @IncomeId, @Payment, @Income, @IncomeDate, @ResidualIncome, @IsMonthEnd, @FinanceIncome, @FinanceResidualIncome,@FinancePaymentAmount

		WHILE @@FETCH_STATUS = 0
		BEGIN	
			--Initialize values for each income record
			SET @IsAmendmentRecord = 0
			SET @RunningResidualIncomeAmountForPayment = @RunningResidualIncomeAmountForPayment + @ResidualIncome
			SET @RunningResidualIncomeAmountForAmendment = @RunningResidualIncomeAmountForAmendment + @ResidualIncome
			SET @RunningFinanceResidualIncomeAmountForPayment =  @RunningFinanceResidualIncomeAmountForPayment + @FinanceResidualIncome
			SET @RunningResidualIncomeAmountForAmendment = @RunningFinanceResidualIncomeAmountForAmendment + @FinanceResidualIncome
			If  Exists (SELECT EndDate from #PaymentEndDates where EndDate = @IncomeDate)
				SET @IsPaymentEndDate = 1
			else
				SET @IsPaymentEndDate = 0

			--Set Values for amendment record
			IF EXISTS (Select * From #LeaseAmendments Where AmendmentDate = @IncomeDate)
			BEGIN
			SET @IsAmendmentRecord = 1
			Select Top 1 @TotalIncomeBalance = Income_Amount,@LessorRisk = (BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)), @CalculatedResidualIncomeBalance = @LessorRisk - ResidualIncome_Amount From #LeaseAmendments Where AmendmentDate = @IncomeDate and AssetId = @AssetIdToModify Order By AmendmentId Desc
			SELECT Top 1 @TotalFinanceIncomeBalance = FinanceIncome_Amount,@LessorRiskForFinanceAsset =(BookedResidual_Amount - (CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount)),  @CalculatedFinanceResidualIncomeBalance = @LessorRiskForFinanceAsset - FinanceResidualIncome_Amount  From #LeaseAmendments Where AmendmentDate = @IncomeDate and AssetId = @AssetIdToModify and IsLeaseAsset=0 Order By AmendmentId Desc
			END
	
			--Update Income accrued and residual income balance
			IF @IsAmendmentRecord = 0
				UPDATE #IncomeSchedules SET 
				IncomeAccrued_Amount = CASE WHEN @PreviousPaymentFound = 1 THEN @Income ELSE (@Income + @PreviousIncomeAmount) END,
				FinanceIncomeAccrued_Amount = CASE WHEN @PreviousPaymentFound = 1 THEN @FinanceIncome ELSE (@FinanceIncome + @PreviousFinanceIncome) END,
				FinanceResidualIncomeBalance_Amount = CASE WHEN @IsPaymentEndDate = 1 THEN @PreviousFinanceResidualIncome + @RunningResidualIncomeAmountForPayment ELSE @PreviousFinanceResidualIncome END,
				ResidualIncomeBalance_Amount = CASE WHEN @IsPaymentEndDate = 1 THEN @PreviousResidualIncome + @RunningResidualIncomeAmountForPayment ELSE @PreviousResidualIncome END
				WHERE Id = @IncomeId
			ELSE
			BEGIN
				UPDATE #IncomeSchedules SET 
				IncomeAccrued_Amount = CASE WHEN @PreviousPaymentFound = 1 THEN @Income ELSE (@Income + @PreviousIncomeAmount) END,
				FinanceIncomeAccrued_Amount = CASE WHEN @PreviousPaymentFound = 1 THEN @FinanceIncome ELSE (@FinanceIncome + @PreviousFinanceIncome) END,
				FinanceResidualIncomeBalance_Amount = @CalculatedFinanceResidualIncomeBalance + @RunningFinanceResidualIncomeAmountForAmendment,
				ResidualIncomeBalance_Amount = @CalculatedResidualIncomeBalance + (@RunningResidualIncomeAmountForAmendment)
				WHERE Id = @IncomeId
			END

			--Update Income Balance and Deferred Selling Profit Income Balance
			IF @IsAmendmentRecord = 0
				UPDATE #IncomeSchedules SET 
				IncomeBalance_Amount = CASE WHEN @IsPaymentEndDate = 1 THEN @PreviousIncomeBalance - IncomeAccrued_Amount ELSE @PreviousIncomeBalance END,
				FinanceIncomeBalance_Amount = CASE WHEN @IsPaymentEndDate = 1 THEN @PreviousFinanceIncomeBalance - FinanceIncomeAccrued_Amount ELSE @PreviousFinanceIncomeBalance END,
				DeferredSellingProfitIncomeBalance_Amount = @PreviousDeferredSellingProfitIncomeBalance - DeferredSellingProfitIncome_Amount
				WHERE Id = @IncomeId
			ELSE
			BEGIN
				UPDATE #IncomeSchedules SET 
				IncomeBalance_Amount = @TotalIncomeBalance - @RunningIncomeAmount  - @Income,
				FinanceIncomeBalance_Amount = @TotalFinanceIncomeBalance - @RunningFinanceIncomeAmount - @FinanceIncome,
				DeferredSellingProfitIncomeBalance_Amount = @PreviousDeferredSellingProfitIncomeBalance - DeferredSellingProfitIncome_Amount
				WHERE Id = @IncomeId
			END

			UPDATE #IncomeSchedules SET BeginNetBookValue_Amount = @PreviousEndNBV,FinanceBeginNetBookValue_Amount = @PreviousFinanceEndNBV WHERE Id = @IncomeId

			UPDATE #IncomeSchedules SET 				
			EndNetBookValue_Amount = CASE WHEN @IsPaymentEndDate = 1 THEN BeginNetBookValue_Amount - @Payment + IncomeAccrued_Amount ELSE BeginNetBookValue_Amount - @Payment END,
			FinanceEndNetBookValue_Amount = CASE WHEN @IsPaymentEndDate =1 THEN FinanceBeginNetBookValue_Amount - @FinancePaymentAmount + FinanceIncomeAccrued_Amount ELSE FinanceBeginNetBookValue_Amount- @FinancePaymentAmount END
			WHERE Id = @IncomeId

		
			IF @IncomeDate = @LastPaymentDate AND @LastPaymentDate >= (SELECT StartDate from #MaturityPayment) AND  @LastPaymentDate <= (SELECT EndDate from #MaturityPayment)
			BEGIN
				IF @LessorRisk != 0 
				BEGIN
				   -- This code added to adjust the last payment total income amort. Same will work for monthly leases
				    
					Set @TotalLastPaymentIncome = 0
					IF @IsAdvance = 1 AND (@PaymentFrequency != 'Monthly' OR @DueDay != 1)
						Select @TotalLastPaymentIncome = SUM(Income_Amount) From #IncomeSchedules Where IncomeDate >= @LastPaymentDate

					SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Where Payment_Amount != 0 Order By IncomeDate Desc);
					IF(@AssetIncomeScheduleId IS NULL)
						SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Order By IncomeDate Desc);

					UPDATE #IncomeSchedules SET 
					Payment_Amount = Payment_Amount + (EndNetBookValue_Amount - @LessorRisk) + @TotalLastPaymentIncome,
					EndNetBookValue_Amount = EndNetBookValue_Amount - (EndNetBookValue_Amount - @LessorRisk) - @TotalLastPaymentIncome
					WHERE Id = @AssetIncomeScheduleId
				END
				ELSE
				BEGIN
					SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Where Payment_Amount != 0 Order By IncomeDate Desc);
					IF(@AssetIncomeScheduleId IS NULL)
						SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Order By IncomeDate Desc);

					UPDATE #IncomeSchedules SET 
					Payment_Amount = Payment_Amount + EndNetBookValue_Amount,
					EndNetBookValue_Amount = 0
					WHERE Id = @AssetIncomeScheduleId
				END
				IF @LessorRiskForFinanceAsset !=0
				BEGIN
				
					Set @TotalLastPaymentIncome = 0
					IF @IsAdvance = 1 AND (@PaymentFrequency != 'Monthly' OR @DueDay != 1)
						Select @TotalLastPaymentIncome = SUM(FinanceIncome_Amount) From #IncomeSchedules Where IncomeDate >= @LastPaymentDate

					SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Where FinancePayment_Amount != 0 Order By IncomeDate Desc);
					IF(@AssetIncomeScheduleId IS NULL)
						SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Order By IncomeDate Desc);

					UPDATE #IncomeSchedules SET 
					FinancePayment_Amount = FinancePayment_Amount + (FinanceEndNetBookValue_Amount - @LessorRiskForFinanceAsset) + @TotalLastPaymentIncome,
					FinanceEndNetBookValue_Amount = FinanceEndNetBookValue_Amount - (FinanceEndNetBookValue_Amount - @LessorRiskForFinanceAsset) - @TotalLastPaymentIncome
					WHERE Id = @AssetIncomeScheduleId
				END
				ELSE
				BEGIN
				   SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Where FinancePayment_Amount != 0 Order By IncomeDate Desc);
					IF(@AssetIncomeScheduleId IS NULL)
						SET @AssetIncomeScheduleId = (Select Top 1 Id From #IncomeSchedules Order By IncomeDate Desc);

					UPDATE #IncomeSchedules SET
					FinancePayment_Amount = FinancePayment_Amount + FinanceEndNetBookValue_Amount,
					FinanceEndNetBookValue_Amount =0
					WHERE Id = @AssetIncomeScheduleId
				END
			END

			IF(@IsLeaseAsset = 1)
			BEGIN
			 UPDATE #IncomeSchedules SET
			 LeaseIncome_Amount = Income_Amount,
			 LeaseBeginNetBookValue_Amount = BeginNetBookValue_Amount,
			 LeaseEndNetBookValue_Amount = EndNetBookValue_Amount
			 where Id = @IncomeId
			END

			IF @IsPaymentEndDate = 1
			BEGIN
				SET @PreviousPaymentFound = 1
				SET @RunningResidualIncomeAmountForPayment = 0
			END
			ELSE
				SET @PreviousPaymentFound = 0

       
			SET @RunningIncomeAmount = @RunningIncomeAmount + @Income
			set @RunningFinanceIncomeAmount = @RunningFinanceIncomeAmount + @FinanceIncome

			SELECT @PreviousIncomeAmount = IncomeAccrued_Amount,@PreviousFinanceIncome = FinanceIncomeAccrued_Amount, @PreviousIncomeBalance = IncomeBalance_Amount,@PreviousFinanceIncomeBalance = FinanceIncomeBalance_Amount, @PreviousDeferredSellingProfitIncomeBalance = DeferredSellingProfitIncomeBalance_Amount,
			@PreviousEndNBV = EndNetBookValue_Amount,@PreviousFinanceEndNBV = FinanceEndNetBookValue_Amount, @PreviousResidualIncome = ResidualIncomeBalance_Amount,@PreviousFinanceResidualIncome = FinanceResidualIncomeBalance_Amount FROM #IncomeSchedules WHERE Id = @IncomeId
			
			

			IF EXISTS (Select * From #LeaseAmendments Where AmendmentDate = @IncomeDate)
			BEGIN
				Select Top 1  @PreviousEndNBV = @PreviousEndNBV + CapitalizedIDC_Amount
				From #LeaseAmendments Where AmendmentDate = @IncomeDate and AssetId = @AssetIdToModify and AmendmentAtInception = 0 Order By AmendmentId Desc
			END

			FETCH NEXT FROM IncomeCur
			INTO @IncomeId, @Payment, @Income, @IncomeDate, @ResidualIncome, @IsMonthEnd,@FinanceIncome,@FinanceResidualIncome,@FinancePaymentAmount
			;
			
		END		

		CLOSE IncomeCur;
		DEALLOCATE IncomeCur;

		Update AssetIncomeSchedules Set  AssetIncomeSchedules.BeginNetBookValue_Amount = #IncomeSchedules.BeginNetBookValue_Amount
		, AssetIncomeSchedules.EndNetBookValue_Amount = #IncomeSchedules.EndNetBookValue_Amount
		, AssetIncomeSchedules.Income_Amount = #IncomeSchedules.Income_Amount
		, AssetIncomeSchedules.IncomeAccrued_Amount = #IncomeSchedules.IncomeAccrued_Amount
		, AssetIncomeSchedules.IncomeBalance_Amount = #IncomeSchedules.IncomeBalance_Amount
		, AssetIncomeSchedules.ResidualIncome_Amount = #IncomeSchedules.ResidualIncome_Amount
		, AssetIncomeSchedules.ResidualIncomeBalance_Amount = #IncomeSchedules.ResidualIncomeBalance_Amount
		, AssetIncomeSchedules.Payment_Amount = #IncomeSchedules.Payment_Amount
		, AssetIncomeSchedules.FinanceIncome_Amount = #IncomeSchedules.FinanceIncome_Amount
		, AssetIncomeSchedules.FinanceIncomeBalance_Amount = #IncomeSchedules.FinanceIncomeBalance_Amount
		, AssetIncomeSchedules.FinanceIncomeAccrued_Amount = #IncomeSchedules.FinanceIncomeAccrued_Amount
		, AssetIncomeSchedules.FinanceResidualIncome_Amount = #IncomeSchedules.FinanceResidualIncome_Amount
		, AssetIncomeSchedules.FinanceResidualIncomeBalance_Amount = #IncomeSchedules.FinanceResidualIncomeBalance_Amount
		,AssetIncomeSchedules.FinanceBeginNetBookValue_Amount = #IncomeSchedules.FinanceBeginNetBookValue_Amount
		,AssetIncomeSchedules.FinanceEndNetBookValue_Amount = #IncomeSchedules.FinanceEndNetBookValue_Amount
		,AssetIncomeSchedules.LeaseBeginNetBookValue_Amount = #IncomeSchedules.LeaseBeginNetBookValue_Amount,
		AssetIncomeSchedules.LeaseEndNetBookValue_Amount = #IncomeSchedules.LeaseEndNetBookValue_Amount
		,AssetIncomeSchedules.LeaseIncome_Amount = #IncomeSchedules.LeaseIncome_Amount
		From AssetIncomeSchedules 
		Inner Join #IncomeSchedules On #IncomeSchedules.Id = AssetIncomeSchedules.Id;


		DROP TABLE #IncomeSchedules;
		FETCH NEXT FROM AssetCur INTO @AssetIdToModify;
END	

CLOSE AssetCur;
DEALLOCATE AssetCur;
DROP TABLE #NewlyCreatedAssetIds
END
END

--update lease income schedules
BEGIN
	WITH CTE_AssetIncomes AS
	(
	SELECT LeaseIncomeScheduleId,AssetIncomeSchedules.AssetId,IsLeaseAsset,AssetIncomeSchedules.BeginNetBookValue_Amount,AssetIncomeSchedules.EndNetBookValue_Amount,AssetIncomeSchedules.Payment_Amount,AssetIncomeSchedules.Income_Amount,
			AssetIncomeSchedules.IncomeAccrued_Amount,AssetIncomeSchedules.IncomeBalance_Amount, AssetIncomeSchedules.ResidualIncome_Amount,AssetIncomeSchedules.ResidualIncomeBalance_Amount,AssetIncomeSchedules.DeferredSellingProfitIncome_Amount,
			AssetIncomeSchedules.DeferredSellingProfitIncomeBalance_Amount, AssetIncomeSchedules.RentalIncome_Amount,AssetIncomeSchedules.DeferredRentalIncome_Amount,AssetIncomeSchedules.OperatingBeginNetBookValue_Amount,
			AssetIncomeSchedules.OperatingEndNetBookValue_Amount,AssetIncomeSchedules.Depreciation_Amount 
	FROM AssetIncomeSchedules JOIN LeaseIncomeSchedules ON AssetIncomeSchedules.LeaseIncomeScheduleId = LeaseIncomeSchedules.Id
			JOIN LeaseAssets ON LeaseIncomeSchedules.LeaseFinanceId = LeaseAssets.LeaseFinanceId AND AssetIncomeSchedules.AssetId = LeaseAssets.AssetId
			JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseIncomeSchedules.LeaseFinanceId = LeaseFinances.Id
	WHERE IsSchedule = 1 AND AssetIncomeSchedules.IsActive = 1 AND LeaseFinances.ContractId = @ContractIdToConsider
	),
	CTE_LeaseAssetIncome AS
	(
	SELECT LeaseIncomeScheduleId,AssetId,BeginNetBookValue_Amount,EndNetBookValue_Amount,Payment_Amount,Income_Amount,IncomeAccrued_Amount,IncomeBalance_Amount, ResidualIncome_Amount,ResidualIncomeBalance_Amount,DeferredSellingProfitIncome_Amount,
			DeferredSellingProfitIncomeBalance_Amount, RentalIncome_Amount,DeferredRentalIncome_Amount,OperatingBeginNetBookValue_Amount,OperatingEndNetBookValue_Amount,Depreciation_Amount 
	FROM CTE_AssetIncomes WHERE IsLeaseAsset=1
	),
	CTE_FinanceAssetIncome AS
	(
	SELECT LeaseIncomeScheduleId,AssetId,BeginNetBookValue_Amount,EndNetBookValue_Amount,Payment_Amount,Income_Amount, IncomeAccrued_Amount,IncomeBalance_Amount, ResidualIncome_Amount,ResidualIncomeBalance_Amount, RentalIncome_Amount,DeferredRentalIncome_Amount 
	FROM CTE_AssetIncomes WHERE IsLeaseAsset=0
	),
	CTE_LeaseIncome AS
	(
	Select CTE_AssetIncomes.LeaseIncomeScheduleId, BeginNetBookValue = ISNULL(SUM(LeaseAssetIncome.BeginNetBookValue_Amount),0),
			EndNetBookValue = ISNULL(SUM(LeaseAssetIncome.EndNetBookValue_Amount),0), Payment = ISNULL(SUM(LeaseAssetIncome.Payment_Amount),0), 
			Income = ISNULL(SUM(LeaseAssetIncome.Income_Amount),0), IncomeAccrued = ISNULL(SUM(LeaseAssetIncome.IncomeAccrued_Amount),0),
			IncomeBalance = ISNULL(SUM(LeaseAssetIncome.IncomeBalance_Amount),0), ResidualIncome = ISNULL(SUM(LeaseAssetIncome.ResidualIncome_Amount),0), 
			ResidualIncomeBalance = ISNULL(SUM(LeaseAssetIncome.ResidualIncomeBalance_Amount),0), DSPIncome = ISNULL(SUM(LeaseAssetIncome.DeferredSellingProfitIncome_Amount),0), 
			DSPIncomeBalance = ISNULL(SUM(LeaseAssetIncome.DeferredSellingProfitIncomeBalance_Amount),0), RentalIncome = ISNULL(SUM(LeaseAssetIncome.RentalIncome_Amount),0), 
			DeferredRentalIncome = ISNULL(SUM(LeaseAssetIncome.DeferredRentalIncome_Amount),0), OperatingBeginNBV = ISNULL(SUM(LeaseAssetIncome.OperatingBeginNetBookValue_Amount),0),
			OperatingEndNBV = ISNULL(SUM(LeaseAssetIncome.OperatingEndNetBookValue_Amount),0), Depreciation = ISNULL(SUM(LeaseAssetIncome.Depreciation_Amount),0), 
			FinanceBeginNBV = ISNULL(SUM(FinanceAssetIncome.BeginNetBookValue_Amount),0), FinanceEndNBV = ISNULL(SUM(FinanceAssetIncome.EndNetBookValue_Amount),0),
			FinancePayment = ISNULL(SUM(FinanceAssetIncome.Payment_Amount),0), FinanceIncome = ISNULL(SUM(FinanceAssetIncome.Income_Amount),0),
			FinanceIncomeAccrued = ISNULL(SUM(FinanceAssetIncome.IncomeAccrued_Amount),0), FinanceIncomeBalance = ISNULL(SUM(FinanceAssetIncome.IncomeBalance_Amount),0), 
			FinanceResidualIncome = ISNULL(SUM(FinanceAssetIncome.ResidualIncome_Amount),0), FinanceResidualIncomeBalance = ISNULL(SUM(FinanceAssetIncome.ResidualIncomeBalance_Amount),0), 
			FinanceRentalIncome = ISNULL(SUM(FinanceAssetIncome.RentalIncome_Amount),0),FinanceDeferredRentalIncome = ISNULL(SUM(FinanceAssetIncome.DeferredRentalIncome_Amount),0)  
	from CTE_AssetIncomes Left Join CTE_LeaseAssetIncome LeaseAssetIncome 
			ON CTE_AssetIncomes.LeaseIncomeScheduleId = LeaseAssetIncome.LeaseIncomeScheduleId AND CTE_AssetIncomes.AssetId = LeaseAssetIncome.AssetId
			Left Join CTE_FinanceAssetIncome FinanceAssetIncome ON CTE_AssetIncomes.LeaseIncomeScheduleId = FinanceAssetIncome.LeaseIncomeScheduleId AND CTE_AssetIncomes.AssetId = FinanceAssetIncome.AssetId
	GROUP BY CTE_AssetIncomes.LeaseIncomeScheduleId
	)
	Update LeaseIncomeSchedules Set BeginNetBookValue_Amount = BeginNetBookValue,EndNetBookValue_Amount = EndNetBookValue,OperatingBeginNetBookValue_Amount = OperatingBeginNBV,OperatingEndNetBookValue_Amount = OperatingEndNBV,Depreciation_Amount = Depreciation,
	Income_Amount = Income, IncomeAccrued_Amount = IncomeAccrued,IncomeBalance_Amount= IncomeBalance,RentalIncome_Amount = RentalIncome,DeferredRentalIncome_Amount = DeferredRentalIncome,ResidualIncome_Amount = ResidualIncome,ResidualIncomeBalance_Amount = ResidualIncomeBalance, 
	Payment_Amount = LeaseIncome.Payment,FinanceBeginNetBookValue_Amount = FinanceBeginNBV ,FinanceEndNetBookValue_Amount = FinanceEndNBV,FinanceIncome_Amount = FinanceIncome,FinanceIncomeAccrued_Amount = FinanceIncomeAccrued,FinanceIncomeBalance_Amount = FinanceIncomeBalance,
	FinanceRentalIncome_Amount = FinanceRentalIncome, FinanceDeferredRentalIncome_Amount = FinanceDeferredRentalIncome, FinanceResidualIncome_Amount = FinanceResidualIncome, FinanceResidualIncomeBalance_Amount = FinanceResidualIncomeBalance,FinancePayment_Amount = FinancePayment,
	DeferredSellingProfitIncome_Amount = DSPIncome,DeferredSellingProfitIncomeBalance_Amount = DSPIncomeBalance, UpdatedById = @UserId, UpdatedTime = @Time 
	from  LeaseIncomeSchedules JOIN CTE_LeaseIncome LeaseIncome ON LeaseIncomeSchedules.Id = LeaseIncome.LeaseIncomeScheduleId;
END

BEGIN -- Income And Receivable Adjustment

	SELECT AssetId, SUM(AssetIncomeSchedules.Payment_Amount) [TotalPaymentAmount],SUM(AssetIncomeSchedules.FinancePayment_Amount) [TotalFinancePaymentAmount] INTO #TotalAssetIncome FROM AssetIncomeSchedules 
	Inner Join LeaseIncomeSchedules On LeaseIncomeSchedules.Id = AssetIncomeSchedules.LeaseIncomeScheduleId And LeaseIncomeSchedules.IsSchedule = 1
	Inner Join #SplitedAssets On #SplitedAssets.NewAssetId = AssetIncomeSchedules.AssetId
	Where AssetIncomeSchedules.IsActive = 1 AND (@ReaccrualPaymentDate IS NULL OR IncomeDate >= @ReaccrualPaymentDate)
	GROUP BY AssetIncomeSchedules.AssetId

	Select AssetId, SUM(CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount) [TotalGuaranteed]  INTO #TotalGuaranteedResidual
	From LeaseAssets 	
	Inner Join #SplitedAssets On #SplitedAssets.NewAssetId = LeaseAssets.AssetId
	Where LeaseAssets.IsActive = 1 And LeaseAssets.LeaseFinanceId = @LeaseFinanceId
	GROUP BY LeaseAssets.AssetId	
	
	
	Select AssetId, SUM(CustomerGuaranteedResidual_Amount + ThirdPartyGuaranteedResidual_Amount) [TotalGuaranteedForFinanceAsset]  INTO #TotalGuaranteedResidualForFinanceAsset
	From LeaseAssets 	
	Inner Join #SplitedAssets On #SplitedAssets.NewAssetId = LeaseAssets.AssetId
	Where LeaseAssets.IsActive = 1 And LeaseAssets.LeaseFinanceId = @LeaseFinanceId And LeaseAssets.IsLeaseAsset = 0
	GROUP BY LeaseAssets.AssetId	

	SELECT AssetId, SUM(ReceivableDetails.Amount_Amount) [TotalReceivableAmount], SUM(ReceivableDetails.NonLeaseComponentAmount_Amount) [TotalNonLeaseComponentAmount],Max(Receivables.Duedate) [DueDate], NULL [ReceivableDetailId] INTO #TotalReceivableIncome FROM ReceivableDetails 
	INNER JOIN #SplitedAssets ON #SplitedAssets.NewAssetId = ReceivableDetails.AssetId AND ReceivableDetails.IsActive = 1
	INNER JOIN Receivables ON Receivables.Id = ReceivableDetails.ReceivableId AND Receivables.IsActive = 1
	INNER JOIN LeasePaymentSchedules ON LeasePaymentSchedules.Id = Receivables.PaymentScheduleId AND LeasePaymentSchedules.IsActive = 1
	WHERE IncomeType NOT IN ('_','InterimInterest')
	GROUP BY ReceivableDetails.AssetId	
	
	UPDATE #TotalReceivableIncome
	SET ReceivableDetailId = R.ReceivableDetailId
	FROM #TotalReceivableIncome JOIN
		 (SELECT #TotalReceivableIncome.AssetId, MAX(ReceivableDetails.Id) 'ReceivableDetailId' 
		  FROM Receivables JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive = 1 AND ReceivableDetails.IsActive = 1
		  JOIN #TotalReceivableIncome ON Receivables.DueDate = #TotalReceivableIncome.DueDate AND ReceivableDetails.AssetId = #TotalReceivableIncome.AssetId
		  JOIN LeasePaymentSchedules ON LeasePaymentSchedules.Id = Receivables.PaymentScheduleId AND LeasePaymentSchedules.IsActive = 1
		  WHERE IncomeType NOT IN ('_','InterimInterest')
		  GROUP BY #TotalReceivableIncome.AssetId
		 ) R ON #TotalReceivableIncome.AssetId = R.AssetId

	INSERT INTO #ReceivableDetailInfo (Id, ReceivableId, Adjustment_Amount)
	SELECT ReceivableDetails.Id, ReceivableDetails.ReceivableId, Adjustment_Amount = TotalPaymentAmount - TotalReceivableAmount - TotalGuaranteed
	FROM ReceivableDetails
		 INNER JOIN #TotalReceivableIncome ON #TotalReceivableIncome.ReceivableDetailId = ReceivableDetails.Id
		 INNER JOIN #TotalAssetIncome ON #TotalAssetIncome.AssetId = #TotalReceivableIncome.AssetId
		 INNER JOIN #TotalGuaranteedResidual ON #TotalGuaranteedResidual.AssetId = #TotalAssetIncome.AssetId
		 
		 INSERT INTO #ReceivableDetailInfoForFinanceAsset (Id, ReceivableId, Adjustment_Amount)
	SELECT ReceivableDetails.Id, ReceivableDetails.ReceivableId, Adjustment_Amount = TotalPaymentAmount - TotalReceivableAmount - TotalGuaranteedForFinanceAsset
	FROM ReceivableDetails
		 INNER JOIN #TotalReceivableIncome ON #TotalReceivableIncome.ReceivableDetailId = ReceivableDetails.Id
		 INNER JOIN #TotalAssetIncome ON #TotalAssetIncome.AssetId = #TotalReceivableIncome.AssetId
	     INNER JOIN  #TotalGuaranteedResidualForFinanceAsset on #TotalGuaranteedResidualForFinanceAsset.AssetId = #TotalAssetIncome.AssetId

		

	UPDATE ReceivableDetails SET Amount_Amount = ReceivableDetails.Amount_Amount + #ReceivableDetailInfo.Adjustment_Amount,
	Balance_Amount = ReceivableDetails.Balance_Amount + #ReceivableDetailInfo.Adjustment_Amount, 
	EffectiveBalance_Amount = ReceivableDetails.EffectiveBalance_Amount + #ReceivableDetailInfo.Adjustment_Amount
	
	FROM ReceivableDetails JOIN #ReceivableDetailInfo ON ReceivableDetails.Id = #ReceivableDetailInfo.Id

	if(@IsLeaseAsset=1)
	BEGIN
	 UPDATE ReceivableDetails SET LeaseComponentAmount_Amount =LeaseComponentAmount_Amount + #ReceivableDetailInfo.Adjustment_Amount
	  FROM ReceivableDetails JOIN #ReceivableDetailInfo ON ReceivableDetails.Id = #ReceivableDetailInfo.Id
	END
	UPDATE ReceivableDetails set
	NonLeaseComponentAmount_Amount = ReceivableDetails.NonLeaseComponentAmount_Amount + #ReceivableDetailInfoForFinanceAsset.Adjustment_Amount
	FROM ReceivableDetails JOIN #ReceivableDetailInfoForFinanceAsset ON ReceivableDetails.Id = #ReceivableDetailInfoForFinanceAsset.Id
		
	UPDATE Receivables SET TotalAmount_Amount = TotalAmount_Amount + Adjustment_Amount,
	TotalBalance_Amount = TotalBalance_Amount + Adjustment_Amount,
	TotalEffectiveBalance_Amount = TotalEffectiveBalance_Amount + Adjustment_Amount
	FROM Receivables JOIN 
	(
		SELECT ReceivableId, SUM(Adjustment_Amount) [Adjustment_Amount] FROM #ReceivableDetailInfo GROUP BY ReceivableId
	) ReceivableInfo ON Receivables.Id = ReceivableInfo.ReceivableId 

END
BEGIN -- Blended Item Assets
SET @TableName = 'BlendedItemAssets';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[LeaseAssetId],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');

SET @ColumnList = REPLACE(@columnList, ',[LeaseAssetId]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');

SET @InsertQuery = 'MERGE INTO BlendedItemAssets AS T1
USING (SELECT '+ @ColumnList + ', Id , #LeaseAssetsTemp.NewAssetId, #LeaseAssetsTemp.OldAssetId, NewId FROM BlendedItemAssets
JOIN #LeaseAssetsTemp On BlendedItemAssets.LeaseAssetId = #LeaseAssetsTemp.OldId WHERE #LeaseAssetsTemp.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , LeaseAssetId , CreatedById , CreatedTime  ) VALUES
(
' + @ColumnList + ', NewId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
)OUTPUT Inserted.Id, S1.Id, S1.NewAssetId, S1.OldAssetId Into #BlendedItemAssetsTemp;'
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @InsertQuery = @InsertQuery + 'INSERT INTO #BlendedItemAssetsTemp
SELECT DISTINCT #BlendedItemAssetsTemp.OldId, #BlendedItemAssetsTemp.OldId ,#SplitedAssets.NewAssetID,#SplitedAssets.OldAssetID  from #BlendedItemAssetsTemp join #SplitedAssets On #BlendedItemAssetsTemp.OldAssetID = #SplitedAssets.NewAssetID WHERE #SplitedAssets.FeatureAsset=1;'
END
SET @InsertQuery = @InsertQuery + 'DELETE FROM AssetSplitTemp where JobInstanceId='+@JobInstanceIdInString +'; INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
SELECT NewId, OldId ,Prorate , IsLastAsset, '+@JobInstanceIdInString +'  from #BlendedItemAssetsTemp join #SplitedAssets On #BlendedItemAssetsTemp.NewAssetID = #SplitedAssets.NewAssetID;'
EXEC(@InsertQuery)
--Update Record in Blended Item Assets
SET @UpdateColumnName = 'Id'
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + 'UPDATE BlendedItemAssets SET IsActive = 0, UpdatedById = ' + CAST(@UserId AS NVARCHAR(10)) + ' ,UpdatedTime = ''' + CAST(@Time AS NVARCHAR(MAX)) + ''' FROM BlendedItemAssets JOIN #BlendedItemAssetsTemp ON BlendedItemAssets.Id = #BlendedItemAssetsTemp.OldId;'
END
EXEC(@UpdateQuery)
END
BEGIN -- Asset Split Entry
SET @TableName = 'AssetSplitAssetDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @InsertQuery = 'MERGE INTO AssetSplitAssetDetails AS T1
USING (SELECT Assets.Id,#SplitedAssets.NewAssetId,#AssetSplitAssetsTemp.NewId,AssetSplitAssets.OriginalAssetCost_Amount,#SplitedAssets.Quantity FROM Assets
JOIN #SplitedAssets On Assets.Id = #SplitedAssets.OldAssetId
JOIN #AssetSplitAssetsTemp On Assets.Id = #AssetSplitAssetsTemp.OldAssetId
JOIN AssetSplitAssets On #AssetSplitAssetsTemp.NewId = AssetSplitAssets.Id
Where #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( NewAssetCost_Amount, NewAssetCost_Currency, NewQuantity, CreatedById, CreatedTime, UpdatedById, UpdatedTime, NewAssetId, AssetSplitAssetId, AssetFeatureId)VALUES
(
OriginalAssetCost_Amount
,''' + CAST(@Currency AS VARCHAR(3))+'''
,Quantity
,' + CAST (1 AS VARCHAR(max)) +'
, ''' + Cast(@Time as Varchar(MAX)) +'''
,null
,null
,NewAssetId
,NewId
,null
)OUTPUT Inserted.Id ,S1.Id , S1.NewAssetId Into #AssetSplitAssetsDetailTemp;';
EXEC(@InsertQuery)
-- Update Asset Split Detail Values
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
INSERT INTO AssetSplitTemp (NewId, OldId ,Prorate , IsLast, JobInstanceId)
Select NewAssetID, OldAssetID, Prorate, IsLastAsset, @JobInstanceId  From #SplitedAssets;
SET @UpdateColumnName = 'NewAssetId';
SET @UpdateQuery = dbo.SplitAmountColumns(@TableName,  @UpdateColumnName,  @UserId, @SplitByType, @Time, @JobInstanceId,0);
IF @SplitByType = 'AssetSplitFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update AssetSplitAssetDetails Set AssetFeatureId = #AssetFeaturesTemp.NewId , NewQuantity = 0 , NewAssetCost_Amount = #AssetParameter.NewAmount FROM AssetSplitAssetDetails JOIN #AssetFeaturesTemp ON AssetSplitAssetDetails.NewAssetId = #AssetFeaturesTemp.NewAssetId JOIN #AssetParameter On #AssetFeaturesTemp.OldId = #AssetParameter.AssetFeatureId' ;
END
EXEC(@UpdateQuery)
END
COMMIT TRAN
END TRY
BEGIN CATCH
ROLLBACK TRAN
END CATCH
END
BEGIN   -- Asset GL Details
SET @TableName = 'AssetGLDetails';
SET @ColumnList = dbo.GetColumnList(@TableName);
SET @ColumnList = REPLACE(@columnList, '[Id],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[CreatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedById],' , '');
SET @ColumnList = REPLACE(@columnList, '[UpdatedTime],' , '');
SET @ColumnList = REPLACE(@columnList, ',[Id]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[CreatedTime]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedById]' , '');
SET @ColumnList = REPLACE(@columnList, ',[UpdatedTime]' , '');
SET @InsertQuery = 'MERGE INTO AssetGLDetails AS T1
USING (SELECT '+ @ColumnList + ', NewAssetId FROM AssetGLDetails
JOIN #SplitedAssets On #SplitedAssets.OldAssetId = AssetGLDetails.Id
Where #SplitedAssets.FeatureAsset = 0) AS S1 ON 1=0
WHEN NOT MATCHED THEN
INSERT ( ' + @ColumnList + '  , Id , CreatedById , CreatedTime ) VALUES
(
' + @ColumnList + ', NewAssetId , ' + Cast( + @UserId as Varchar(MAX)) + ' , ''' + Cast( + @Time as Varchar(MAX)) + '''
);'
EXEC(@InsertQuery)
END

IF EXISTS(SELECT 1 FROM LeaseAssets 
JOIN #SplitedAssets ON LeaseAssets.AssetId = #SplitedAssets.NewAssetID AND LeaseAssets.IsPrimary = 1
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND IsCurrent=1)
BEGIN
	IF @SplitByType = 'AssetSplitFeature'
	BEGIN
		SELECT 
			DISTINCT NewAssetID AS Id 
		INTO #NewAssetIds 
		FROM #SplitedAssets
		WHERE NewAssetID != OldAssetID

		UPDATE 
			LeaseAssets 
			SET IsPrimary = 0 
		FROM LeaseAssets
		INNER JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1
		JOIN #NewAssetIds AssetIds ON LeaseAssets.AssetId =  AssetIds.Id 
		WHERE LeaseAssets.IsPrimary=1

	END
	ELSE IF(@SplitByType = 'AssetSplit')
	BEGIN
		SELECT 
			DISTINCT NewAssetID,OldAssetID 
		INTO #NewAssetsCreatedOnSplit 
		FROM #SplitedAssets
		
		SELECT
			 SecondaryLeaseAsset.LeaseAssetId AS Id 
		INTO #SecondaryAssetsAfterSplit FROM 
		(
			SELECT ROW_NUMBER() OVER(PARTITION BY AssetIds.OldAssetID ORDER BY LeaseAssets.NBV_Amount DESC,LeaseAssets.AssetId ASC) AS RowNumber,
				   LeaseAssets.Id AS LeaseAssetId 
			FROM LeaseAssets
			JOIN LeaseFinances ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
			JOIN #NewAssetsCreatedOnSplit AssetIds ON LeaseAssets.AssetId = AssetIds.NewAssetID			
			WHERE LeaseAssets.IsActive = 1 AND LeaseFinances.IsCurrent = 1 
		) AS SecondaryLeaseAsset WHERE RowNumber !=1

		UPDATE 
			LeaseAssets SET IsPrimary = 0 
		FROM LeaseAssets
		JOIN #SecondaryAssetsAfterSplit AssetIds
		 ON LeaseAssets.Id = AssetIds.Id
		WHERE LeaseAssets.IsPrimary=1
	END
END

-- Paramters to display the log in the job instance page
IF @SplitByType <> 'AssetSplitFeature'
BEGIN
SELECT 
	NewAssetID [NewAssetId] ,
	OldAssetID [OldAssetId],
	0[AssetFeatureId],
	CAST(CASE
			WHEN LeaseAssets.IsPrimary=1 
				THEN 1 
			ELSE 0 END AS BIT) [IsPrimaryAsset]
FROM #SplitedAssets
LEFT JOIN LeaseAssets ON #SplitedAssets.NewAssetId=LeaseAssets.AssetId AND LeaseAssets.IsActive=1

END
ELSE
BEGIN
SELECT	
	#SplitedAssets.NewAssetID [NewAssetId] ,
	#SplitedAssets.OldAssetID [OldAssetId] ,
	#AssetParameter.AssetFeatureId [AssetFeatureId],
	CAST(CASE
			WHEN LeaseAssets.IsPrimary=1 
				THEN 1 
			ELSE 0 END AS BIT) [IsPrimaryAsset]
FROM #SplitedAssets
Join #AssetParameter on #SplitedAssets.OldAssetID = #AssetParameter.AssetId
LEFT JOIN LeaseAssets ON #SplitedAssets.OldAssetId=LeaseAssets.AssetId AND LeaseAssets.IsActive=1
END
DELETE FROM AssetSplitTemp where JobInstanceId=@JobInstanceId
Drop Table #SelectedAssets
Drop Table #DuplicateAssets
Drop Table #SplitedAssets
Drop Table #PayableInvoiceAssetsTemp
Drop Table #PayableInvoiceTemp
Drop Table #PayableInvoiceDepositAssetsTemp
Drop Table #PayableInvoiceNegativeTakedownAssetsTemp
Drop Table #AssetFeaturesTemp
Drop Table #AssetParameter
Drop Table #PayableInvoiceOtherCostsTemp
Drop Table #PayableInvoiceOtherCostDetailsTemp
Drop Table #AssetLocationsTemp
Drop Table #AssetSerialNumbersTemp
Drop Table #AssetMetersTemp
Drop Table #AssetHistoriesTemp
Drop Table #AssetHistoriesMaxTemp
Drop Table #AssetValueHistoriesTemp
Drop Table #AssetValueHistoryDetailsTemp
Drop Table #AssetsLocationChangeDetailsTemp
Drop Table #AssetsValueStatusChangeDetailsTemp
Drop Table #VertexBilledRentalReceivablesTemp
Drop Table #MaturityMonitorFMVAssetDetailsTemp
Drop Table #LoanPaydownAssetDetailsTemp
Drop Table #PropertyTaxDetailsTemp
Drop Table #GLManualJournalEntriesTemp
Drop Table #GLManualJournalEntryDetailsTemp
Drop Table #PayablesTemp
Drop Table #TreasuryPayableDetailsTemp
Drop Table #DisbursementRequestPayablesTemp
Drop Table #DisbursementRequestPayeesTemp
Drop Table #PayableGLJournalsTemp
Drop Table #ChargeOffAssetDetailsTemp
Drop Table #CollateralTrackingTemp
Drop Table #CPIAssetMeterTemp
Drop Table #AssumptionAssetTemp
Drop Table #AppraisalDetailsTemp
Drop Table #CPIScheduleAssetsTemp
Drop Table #CollateralAssetsTemp
Drop Table #AssetSaleDetailsTemp
Drop Table #AssetSalesTradeInsTemp
Drop Table #AssetEnMasseUpdateDetailsTemp
Drop Table #BookDepreciationsTemp
Drop TABLE #BookDepreciationEnMasseUpdateDetailsTemp
Drop Table #BookDepreciationEnMasseSetupDetailsTemp
Drop Table #LienCollateralsTemp
Drop Table #SundryDetailsTemp
Drop Table #SundryRecurringPaymentDetailsTemp
Drop Table #CPIAssetMeterTypesTemp
Drop Table #UDFsTemp
Drop Table #WriteDownAssetDetailsTemp
Drop Table #LeaseAmendmentImpairmentAssetDetailsTemp
Drop Table #LeaseAssetPaymentSchedulesTemp
Drop Table #TaxDepEntitiesTemp
Drop Table #TaxDepAmortizationsTemp
Drop Table #TaxDepAmortizationDetailsTemp
Drop Table #TaxDepEntityEnMasseUpdateDetailsTemp
Drop Table #LeaseAssetsTemp
Drop Table #LeasePreclassificationResultsTemp
Drop Table #PayoffAssetsTemp
Drop Table #AssetFloatRateIncomesTemp
Drop Table #AssetIncomeSchedulesTemp
Drop Table #CapitalizedLeaseAssetsTemp
Drop Table #BlendedItemAssetsTemp
Drop Table #ReceivableDetailsTemp
Drop Table #ReceiptApplicationReceivableDetailsTemp
Drop Table #ReceivableInvoiceDetailsTemp
Drop Table #ReceivableTaxDetailsTemp
Drop Table #ReceivableTaxReversalDetailsTemp
Drop Table #ReceivableTaxImpositionsTemp
Drop Table #ReceiptApplicationReceivableTaxImpositionsTemp
Drop Table #AssetSplitAssetsTemp
Drop Table #AssetSplitAssetsDetailTemp
drop table #GLJournalDetailsTemp
drop table #PayableInvoiceCountTemp
DROP TABLE #OneTimeACHReceivableDetailsTemp
IF OBJECT_ID('tempdb..#CurrentLeaseAssetsInfo') IS NOT NULL
drop table #CurrentLeaseAssetsInfo
IF OBJECT_ID('tempdb..#MaturityPayment') IS NOT NULL
drop table #MaturityPayment
IF OBJECT_ID('tempdb..#ReceivableDetailInfo') IS NOT NULL
drop table #ReceivableDetailInfo
IF OBJECT_ID('tempdb..#AllocationMethodDetails') IS NOT NULL
drop table #AllocationMethodDetails
IF OBJECT_ID('tempdb..#AssetFeatureSplitTemp') IS NOT NULL
drop table #AssetFeatureSplitTemp
IF OBJECT_ID('tempdb..#FeatureSplitInfo') IS NOT NULL
drop Table #FeatureSplitInfo
IF OBJECT_ID('tempdb..#NewAssetIds') IS NOT NULL
DROP TABLE #NewAssetIds 
IF OBJECT_ID('tempdb..#NewAssetsCreatedOnSplit') IS NOT NULL
DROP TABLE #NewAssetsCreatedOnSplit
IF OBJECT_ID('tempdb..#SecondaryAssetsAfterSplit') IS NOT NULL
DROP TABLE #SecondaryAssetsAfterSplit

END
--ROLLBACK TRAN @TEST

GO
