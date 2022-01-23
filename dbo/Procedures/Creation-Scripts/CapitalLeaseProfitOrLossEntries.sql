SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CapitalLeaseProfitOrLossEntries]
(
@CustomerName NVARCHAR(40)=null,
@SequenceNumber NVARCHAR(40)=null,
@ContractType NVARCHAR(40)='_',
@FromDate DATE=null,
@ToDate DATE=null,
@DirectFinanceEnumValue NVARCHAR(40),
@ProfitEnumValue NVARCHAR(40),
@SalesTypeEnumValue NVARCHAR(40),
@IFRSFinanceEnumValue NVARCHAR(40),
@InactiveEnumValue NVARCHAR(40),
@ApprovedEnumValue NVARCHAR(40),
@InsuranceFollowupEnumValue NVARCHAR(40),
@Culture NVARCHAR(10)
)
AS
DECLARE @SelectSql nvarchar(max)
DECLARE @FilterConditions nvarchar(max) = ''
IF @CustomerName IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + ' AND Parties.PartyName = @CustomerName'
END
IF @SequenceNumber IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + ' AND Contracts.SequenceNumber = @SequenceNumber'
END
IF @ContractType <> '_'
BEGIN
SET @FilterConditions = @FilterConditions + ' AND LeaseFinanceDetails.LeaseContractType = @ContractType'
END
IF @FromDate IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + ' AND LeaseFinanceDetails.PostDate >= @FromDate'
END
IF @ToDate IS NOT NULL
BEGIN
SET @FilterConditions = @FilterConditions + ' AND LeaseFinanceDetails.PostDate <= @ToDate'
END
SET @SelectSql = '
create table #LeaseAssetSKUDetails(
	LeaseFinanceId BIGINT,
	Revenue Decimal(16,2),
	CostOfGoodsSold Decimal(16,2),
	IsSKU BIT
);

insert into #LeaseAssetSKUDetails
select 
LeaseAssets.LeaseFinanceId,
sum(LeaseAssetSKUs.FMV_Amount) as Revenue,
sum(LeaseAssetSKUs.NBV_Amount) as CostOfGoodsSold,
1 as IsSKU
from LeaseFinances
INNER JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
WHERE LeaseAssetSKUs.IsLeaseComponent = 1 AND LeaseAssetSKUs.IsActive = 1
group by LeaseAssets.LeaseFinanceId
union
select
LeaseFinances.Id as LeaseFinanceId,
Sum(LeaseAssets.FMV_Amount) as Revenue ,
Sum(LeaseAssets.NBV_Amount) as CostOfGoodsSold,
0 as IsSKU
FROM LeaseAssets
INNER JOIN LeaseFinances
on LeaseAssets.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Assets on LeaseAssets.AssetId = Assets.Id
WHERE LeaseAssets.IsLeaseAsset = 1 and LeaseAssets.IsActive = 1 and Assets.IsSKU = 0
GROUP BY LeaseFinances.Id;

with
LeaseAssetDetails(LeaseFinanceId,Revenue,CostOfGoodsSold)
AS (
select
LeaseFinanceId,
Sum(Revenue) as Revenue ,
Sum(CostOfGoodsSold) as CostOfGoodsSold
FROM #LeaseAssetSKUDetails
GROUP BY LeaseFinanceId
)
SELECT
Contracts.SequenceNumber,
LegalEntities.LegalEntityNumber as ''Legal Entity'',
Parties.PartyName as ''Customer Name'',
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.PostDate,
LeaseFinanceDetails.LeaseContractType,
IsNull(LeaseAssetDetails.Revenue,0) as Revenue,
IsNull(Contracts.LastPaymentAmount_Currency,null) as RevenueCurrency,
IsNull(LeaseAssetDetails.CostOfGoodsSold,0) as CostOfGoodsSold,
IsNull(Contracts.LastPaymentAmount_Currency,null) as CostOfGoodsSoldCurrency,
IsNull(LeaseAssetDetails.Revenue,0) - IsNull(LeaseAssetDetails.CostOfGoodsSold,0) as GrossProfit,
IsNull(Contracts.LastPaymentAmount_Currency,null) as GrossProfitCurrency
FROM
Contracts
inner join LeaseFinances
on Contracts.Id = LeaseFinances.ContractId
inner join LeaseFinanceDetails
on LeaseFinances.Id = LeaseFinanceDetails.Id
inner join Customers
on LeaseFinances.CustomerId = Customers.Id
inner join Parties
on Customers.Id = Parties.Id
inner join LegalEntities
on LeaseFinances.LegalEntityId = LegalEntities.Id
LEFT join LeaseAssetDetails
on	LeaseFinances.Id = LeaseAssetDetails.LeaseFinanceId
and LeaseFinanceDetails.ProfitLossStatus <> @ProfitEnumValue
where leasefinances.IsCurrent = 1 and LeaseFinanceDetails.CommencementDate IS NOT NULL
and (LeaseFinanceDetails.LeaseContractType = @DirectFinanceEnumValue or LeaseFinanceDetails.LeaseContractType = @SalesTypeEnumValue
 or LeaseFinanceDetails.LeaseContractType = @IFRSFinanceEnumValue)
and leasefinances.BookingStatus <> @InactiveEnumValue
and (leasefinances.ApprovalStatus = @ApprovedEnumValue or leasefinances.ApprovalStatus = @InsuranceFollowupEnumValue)
FILTERCONDITIONS
ORDER BY LeaseFinanceDetails.CommencementDate DESC

DROP TABLE #LeaseAssetSKUDetails
'
IF @FilterConditions IS NOT NULL
SET @SelectSql = REPLACE(@SelectSql,'FILTERCONDITIONS',@FilterConditions)
ELSE
SET @SelectSql = REPLACE(@SelectSql,'FILTERCONDITIONS','')
print @SelectSql
EXEC sp_executesql @SelectSql
,N'@CustomerName NVARCHAR(40),
@SequenceNumber NVARCHAR(40),
@ContractType NVARCHAR(40),
@FromDate DATE,
@ToDate DATE,
@DirectFinanceEnumValue NVARCHAR(40),
@IFRSFinanceEnumValue NVARCHAR(40),
@ProfitEnumValue NVARCHAR(40),
@SalesTypeEnumValue NVARCHAR(40),
@InactiveEnumValue NVARCHAR(40),
@ApprovedEnumValue NVARCHAR(40),
@InsuranceFollowupEnumValue NVARCHAR(40)'
,@CustomerName
,@SequenceNumber
,@ContractType
,@FromDate
,@ToDate
,@DirectFinanceEnumValue
,@IFRSFinanceEnumValue
,@ProfitEnumValue
,@SalesTypeEnumValue
,@InactiveEnumValue
,@ApprovedEnumValue
,@InsuranceFollowupEnumValue

GO
