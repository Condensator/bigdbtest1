SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CapitalLeaseResidualComponent]
(
@CustomerName NVARCHAR(40)=null,
@SequenceNumber NVARCHAR(40)=null,
@ContractType NVARCHAR(40)='_',
@DirectFinanceEnumValue NVARCHAR(40),
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
SET @SelectSql = '
create table #LeaseAssetSKUDetails(
	LeaseFinanceId BIGINT,
	ResidualBooked Decimal(16,2),
	CustomerGuaranteedResidual Decimal(16,2),
	ThirdPartyGuaranteedResidual Decimal(16,2),
	ResidualValueInsurance Decimal(16,2)
);

insert into #LeaseAssetSKUDetails
select 
LeaseFinances.Id as LeaseFinanceId,
Sum(LeaseAssetSKUs.BookedResidual_Amount) as ResidualBooked ,
Sum(LeaseAssetSKUs.CustomerGuaranteedResidual_Amount) as CustomerGuaranteedResidual,
Sum(LeaseAssetSKUs.ThirdPartyGuaranteedResidual_Amount) as ThirdPartyGuaranteedResidual,
Sum(LeaseAssetSKUs.ResidualValueInsurance_Amount) as ResidualValueInsurance
from LeaseFinances
INNER JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
INNER JOIN LeaseAssetSKUs ON LeaseAssets.Id = LeaseAssetSKUs.LeaseAssetId
WHERE LeaseAssetSKUs.IsLeaseComponent = 1 AND LeaseAssetSKUs.IsActive = 1
group by LeaseFinances.Id
union
select
LeaseFinances.Id as LeaseFinanceId,
Sum(LeaseAssets.BookedResidual_Amount) as ResidualBooked ,
Sum(LeaseAssets.CustomerGuaranteedResidual_Amount) as CustomerGuaranteedResidual,
Sum(LeaseAssets.ThirdPartyGuaranteedResidual_Amount) as ThirdPartyGuaranteedResidual,
Sum(LeaseAssets.ResidualValueInsurance_Amount) as ResidualValueInsurance
FROM LeaseAssets
INNER JOIN LeaseFinances
on LeaseAssets.LeaseFinanceId = LeaseFinances.Id
INNER JOIN Assets on LeaseAssets.AssetId = Assets.Id
WHERE LeaseAssets.IsLeaseAsset = 1 and LeaseAssets.IsActive = 1 and Assets.IsSKU = 0
GROUP BY LeaseFinances.Id;

with
LeaseAssetDetails(LeaseFinanceId,ResidualBooked,CustomerGuaranteedResidual,ThirdPartyGuaranteedResidual,ResidualValueInsurance)
AS (
select
LeaseFinanceId,
Sum(ResidualBooked) as ResidualBooked ,
Sum(CustomerGuaranteedResidual) as CustomerGuaranteedResidual,
Sum(ThirdPartyGuaranteedResidual) as ThirdPartyGuaranteedResidual,
Sum(ResidualValueInsurance) as ResidualValueInsurance
FROM #LeaseAssetSKUDetails
GROUP BY LeaseFinanceId
)
SELECT
Contracts.SequenceNumber,
LegalEntities.LegalEntityNumber as ''Legal Entity'',
Parties.PartyName as ''Customer Name'',
LeaseFinanceDetails.CommencementDate,
LeaseFinanceDetails.LeaseContractType,
IsNull(LeaseAssetDetails.ResidualBooked,0) as ResidualBooked,
IsNull(Contracts.LastPaymentAmount_Currency,null) as ResidualBookedCurrency,
IsNull(LeaseAssetDetails.CustomerGuaranteedResidual,0) as CustomerGuaranteedResidual,
IsNull(Contracts.LastPaymentAmount_Currency,null) as CustomerGuaranteedResidualCurrency,
IsNull(LeaseAssetDetails.ThirdPartyGuaranteedResidual,0) as ThirdPartyGuaranteedResidual,
IsNull(Contracts.LastPaymentAmount_Currency,null) as ThirdPartyGuaranteedResidualCurrency,
IsNull(LeaseAssetDetails.ResidualValueInsurance,0) as ResidualValueInsurance,
IsNull(Contracts.LastPaymentAmount_Currency,null) as ResidualValueInsuranceCurrency,
IsNull(LeaseAssetDetails.ResidualBooked,0) -
(IsNull(LeaseAssetDetails.CustomerGuaranteedResidual,0)+IsNull(LeaseAssetDetails.ThirdPartyGuaranteedResidual,0)) as LessorRisk,
IsNull(Contracts.LastPaymentAmount_Currency,null) as LessorRiskCurrency
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
@DirectFinanceEnumValue NVARCHAR(40),
@SalesTypeEnumValue NVARCHAR(40),
@IFRSFinanceEnumValue NVARCHAR(40),
@InactiveEnumValue NVARCHAR(40),
@ApprovedEnumValue NVARCHAR(40),
@InsuranceFollowupEnumValue NVARCHAR(40)'
,@CustomerName
,@SequenceNumber
,@ContractType
,@DirectFinanceEnumValue
,@SalesTypeEnumValue
,@IFRSFinanceEnumValue
,@InactiveEnumValue
,@ApprovedEnumValue
,@InsuranceFollowupEnumValue

GO
