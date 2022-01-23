SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[AssetHistoryReport]  
@FromAssetId BIGINT = NULL,  
@ToAssetId BIGINT = NULL,  
@CustomerId Nvarchar(100) = NULL,  
@ContractId BIGINT = NULL,  
@AsOfDate AS Date = NULL,  
@Culture NVARCHAR(10),
@AssetMultipleSerialNumberType NVARCHAR(10)
AS  
--Declare @FromAssetId BIGINT = 23  
--Declare @ToAssetId BIGINT = NULL  
--Declare @CustomerId Nvarchar(100) = 23  
--Declare @ContractId BIGINT = NULL  
--Declare @AsOfDate AS Date = NULL  
--declare @Culture As nvarchar(50) = 'en-US'  
BEGIN  
SET NOCOUNT ON;
DECLARE @FilterConditions nvarchar(max)  
DECLARE @sql nvarchar(max)  
Set @FilterConditions = ''  
IF @CustomerId IS NOT NULL  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND  Parties.PartyNumber = @CustomerId '  
END  
IF  @ContractId IS NOT NULL  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND LeaseFinances.ContractId = @ContractId  OR  LoanFinances.ContractId = @ContractId '  
END  
IF (@FromAssetId IS NOT NULL AND @FromAssetId > 0) AND (@ToAssetId IS NULL OR @ToAssetId = 0)  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND Assets.Id = @FromAssetId '  
END  
IF (@FromAssetId IS NULL OR @FromAssetId = 0) AND (@ToAssetId IS NOT NULL AND @ToAssetId > 0)  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND Assets.Id = @ToAssetId '  
END  
IF (@FromAssetId IS NOT NULL AND @FromAssetId > 0)AND (@ToAssetId IS NOT NULL AND @ToAssetId > 0)  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND Assets.Id <= @ToAssetId AND Assets.Id >= @FromAssetId'  
END  
IF  @AsOfDate IS NOT NULL  
BEGIN  
SET @FilterConditions = @FilterConditions +  ' AND AssetHistories.AsOfDate <= @AsOfDate '  
END  
SET @sql='  
SELECT Row_Number()  OVER(ORDER BY AssetHistories.AssetId,AssetHistories.Id,ASNH.ID, AssetHistories.AssetId, AssetHistories.AsofDate) AS Row,AssetHistories.Id AS HistoryId,AssetHistories.Reason,AssetHistories.AssetId,ASNH.Id AS SerialHistoryId,ASNH.OldSerialNumber,ASNH.NewSerialNumber INTO #AssetsSerialNumberHistoryDetails from AssetHistories 
INNER JOIN Assets ON AssetHistories.AssetId = Assets.Id  
LEFT JOIN AssetSerialNumberHistories ASNH ON ASNH.AssetHistoryId = AssetHistories.Id
LEFT OUTER JOIN Parties on Assets.CustomerId = Parties.Id  
LEFT OUTER JOIN LeaseAssets On LeaseAssets.AssetId = Assets.Id  
LEFT OUTER JOIN LeaseFinances On LeaseFinances.Id = LeaseAssets.LeaseFinanceId  
LEFT OUTER JOIN CollateralAssets On CollateralAssets.AssetId = Assets.Id  
LEFT OUTER JOIN LoanFinances On LoanFinances.Id = CollateralAssets.LoanFinanceId  
LEFT OUTER JOIn Contracts On Contracts.Id = AssetHistories.ContractId  
WHERE AssetHistories.IsReversed = 0  
FILTERCONDITIONS  
;  

CREATE TABLE #AssetSerialNumberHistoryDetails
		(
			AssetId BIGINT,
			HistoryId BIGINT,
			OldSerialNumber NVARCHAR (max),
			SerialNumber NVARCHAR (max),
			IsCurrent BIT
		)

CREATE TABLE #SerialNumbers
		(
			SerialNumber NVARCHAR (max)
		)

DECLARE @serialRowStart BIGINT = 1,@serialRowEnd BIGINT = (Select MAX(row) from #AssetsSerialNumberHistoryDetails)
DECLARE @PreviousSerialNumber NVARCHAR (max) 
DECLARE @OldSerialNumber NVARCHAR (max)
DECLARE @NewSerialNumber NVARCHAR (max) 
DECLARE @CurrentRowHistoryId bigint
DECLARE @NextRowHistoryId bigint
DECLARE @CurrentRowAssetId bigint 
DECLARE @NextRowAssetId bigint 

WHILE (@serialRowStart <= @serialRowEnd)
	BEGIN
		SET @NextRowHistoryId  =null
		SET @NextRowAssetId  =null

		SELECT  @OldSerialNumber=OldSerialNumber,@NewSerialNumber=NewSerialNumber,@CurrentRowHistoryId=HistoryId,@CurrentRowAssetId=AssetId From #AssetsSerialNumberHistoryDetails where row=@serialRowStart

		SELECT @NextRowHistoryId=HistoryId,@NextRowAssetId=AssetId From #AssetsSerialNumberHistoryDetails where row=(@serialRowStart+1)

		IF(@OldSerialNumber is null AND @NewSerialNumber is not null)
			BEGIN
				INSERT INTO #SerialNumbers VALUES(@NewSerialNumber)
			END

		ELSE IF (@OldSerialNumber is not null AND @NewSerialNumber is null)
			BEGIN
				DELETE FROM #SerialNumbers WHERE SerialNumber=@OldSerialNumber
			END
		ELSE IF (@OldSerialNumber is not null AND @NewSerialNumber is not null)
			BEGIN
				UPDATE #SerialNumbers SET SerialNumber=@NewSerialNumber WHERE SerialNumber=@OldSerialNumber
			END

		IF(@NextRowHistoryId is NULL OR @CurrentRowHistoryId != @NextRowHistoryId)
			BEGIN
				SET @NewSerialNumber = (Select SerialNumber = CASE WHEN count(*) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(SerialNumber) END 
				FROM #SerialNumbers)
				DECLARE @IsCurrent BIT = CASE WHEN (@CurrentRowAssetId != @NextRowAssetId OR @NextRowAssetId is null ) THEN 1 ELSE 0 END
				INSERT INTO #AssetSerialNumberHistoryDetails VALUES(@CurrentRowAssetId,@CurrentRowHistoryId,@PreviousSerialNumber,@NewSerialNumber,@IsCurrent)
				SET @PreviousSerialNumber = @NewSerialNumber
			END
		
		IF(@CurrentRowAssetId != @NextRowAssetId)
			BEGIN
				DELETE FROM #SerialNumbers
				Set @PreviousSerialNumber = null
			END
		SET @serialRowStart = @serialRowStart + 1
	END
create table #AVHTemp(
	AHId bigint,
	AVHId bigint
);
insert into #AVHTemp
SELECT
AssetHistories.Id,
Max(AssetValueHistories.Id)
FROM
AssetHistories
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId = AssetHistories.AssetId AND AssetValueHistories.IncomeDate <= AssetHistories.AsofDate
INNER JOIN Assets ON AssetHistories.AssetId = Assets.Id
LEFT OUTER JOIN Parties on Assets.CustomerId = Parties.Id
LEFT OUTER JOIN LeaseAssets On LeaseAssets.AssetId = Assets.Id
LEFT OUTER JOIN LeaseFinances On LeaseFinances.Id = LeaseAssets.LeaseFinanceId
LEFT OUTER JOIN CollateralAssets On CollateralAssets.AssetId = Assets.Id
LEFT OUTER JOIN LoanFinances On LoanFinances.Id = CollateralAssets.LoanFinanceId
LEFT OUTER JOIn Contracts On Contracts.Id = AssetHistories.ContractId
WHERE AssetHistories.IsReversed = 0 and AssetValueHistories.IsLeaseComponent=1
FILTERCONDITIONS
GROUP BY AssetHistories.Id
union 
SELECT
AssetHistories.Id,
Max(AssetValueHistories.Id)
FROM
AssetHistories
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId = AssetHistories.AssetId AND AssetValueHistories.IncomeDate <= AssetHistories.AsofDate
INNER JOIN Assets ON AssetHistories.AssetId = Assets.Id
LEFT OUTER JOIN Parties on Assets.CustomerId = Parties.Id
LEFT OUTER JOIN LeaseAssets On LeaseAssets.AssetId = Assets.Id
LEFT OUTER JOIN LeaseFinances On LeaseFinances.Id = LeaseAssets.LeaseFinanceId
LEFT OUTER JOIN CollateralAssets On CollateralAssets.AssetId = Assets.Id
LEFT OUTER JOIN LoanFinances On LoanFinances.Id = CollateralAssets.LoanFinanceId
LEFT OUTER JOIn Contracts On Contracts.Id = AssetHistories.ContractId
WHERE AssetHistories.IsReversed = 0 and AssetValueHistories.IsLeaseComponent=0
FILTERCONDITIONS
GROUP BY AssetHistories.Id;
WITH CTE_AssetValueHistory (AssetHistoryId,NetValue_Amount)  
AS  
(  
Select AHId,sum(AssetValueHistories.NetValue_Amount) from #AVHTemp
join AssetValueHistories on AssetValueHistories.Id = #AVHTemp.AVHId
GROUP BY #AVHTemp.AHId  
)
  
SELECT DISTINCT  
AssetHistories.Id,  
AssetHistories.AsOfDate,  
AssetHistories.Reason,  
AssetHistories.Status,  
Users.FirstName + '' '' + Users.LastName [User],  
CTE_AssetValueHistory.NetValue_Amount [NetValue],  
Contracts.SequenceNumber,  
AssetHistories.CreatedTime [SystemTime],  
AssetTypes.Name as [Type],  
Assets.Quantity,  
Manufacturers.Name as [Make],  
Assets.PartNumber as [Model],  
Assets.ModelYear as [Year],  
Assets.AcquisitionDate,  
Assets.Description,  
Assets.Id as [InventoryId],  
Assets.IsEligibleForPropertyTax,  
ASN.SerialNumber [VIN],  
ASNH.OldSerialNumber [OldSerialNumber],  
ASNH.SerialNumber [SerialNumber],  
Parties.PartyName [Customer],  
ISNULL(EntityResources.Value,PropertyTaxReportCodeConfigs.Code) [RepostCode],  
AssetHistories.FinancialType  
FROM  
Assets  
INNER JOIN AssetTypes ON Assets.TypeId = AssetTypes.Id  
INNER JOIN AssetHistories ON AssetHistories.AssetId = Assets.Id  
INNER JOIN Users on AssetHistories.CreatedById = Users.Id  
INNER JOIN #AssetSerialNumberHistoryDetails ASNH on ASNH.HistoryId = AssetHistories.Id
INNER JOIN #AssetSerialNumberHistoryDetails ASN on ASN.AssetId = Assets.Id AND ASN.IsCurrent=1  
LEFT OUTER JOIN Manufacturers on Assets.ManufacturerId = Manufacturers.Id  
LEFT OUTER JOIN LeaseAssets On LeaseAssets.AssetId = Assets.Id  
LEFT OUTER JOIN LeaseFinances On LeaseFinances.Id = LeaseAssets.LeaseFinanceId  
LEFT OUTER JOIN CollateralAssets On CollateralAssets.AssetId = Assets.Id  
LEFT OUTER JOIN LoanFinances On LoanFinances.Id = CollateralAssets.LoanFinanceId  
LEFT OUTER JOIn Contracts On Contracts.Id = AssetHistories.ContractId  
LEFT OUTER JOIN Parties on Assets.CustomerId = Parties.Id  
LEFT OUTER JOIN CTE_AssetValueHistory on AssetHistories.Id = CTE_AssetValueHistory.AssetHistoryId  
LEFT OUTER JOIN PropertyTaxReportCodeConfigs On AssetHistories.PropertyTaxReportCodeId = PropertyTaxReportCodeConfigs.Id  
LEFT OUTER JOIN EntityResources ON PropertyTaxReportCodeConfigs.Id = EntityResources.EntityId  
AND EntityResources.EntityType = ''PropertyTaxReportCodeConfig''  
AND EntityResources.Name = ''Code''  
AND EntityResources.Culture = @Culture  
WHERE AssetHistories.IsReversed = 0  
FILTERCONDITIONS  
ORDER BY AssetHistories.Id  
'  
IF @FilterConditions IS NOT NULL  
SET @sql = REPLACE(@sql, 'FILTERCONDITIONS', @FilterConditions )  
ELSE  
SET @sql = REPLACE(@sql, 'FILTERCONDITIONS', '' )  
END  
EXEC sp_executesql @sql, N'  
@FromAssetId int  
, @ToAssetId int  
, @CustomerId nvarchar(100)  
, @ContractId int  
, @AsOfDate date  
, @Culture NVARCHAR(10)
, @AssetMultipleSerialNumberType NVARCHAR(10)'  
, @FromAssetId  
, @ToAssetId  
, @CustomerId  
, @ContractId  
, @AsOfDate  
, @Culture  
, @AssetMultipleSerialNumberType

GO
