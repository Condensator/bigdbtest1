SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create proc [dbo].[DisbursementRequestAssetDetail]
(
@DisbursementId BigInt,
@Culture NVARCHAR(10),
@AssetMultipleSerialNumberType NVARCHAR(10)
)
As
--Declare @DisbursementId BigInt = 10459;
Begin
SET NOCOUNT ON;
DECLARE @sql nvarchar(max)
SET @sql='
;WITH CTE_AssetDetails AS (
Select Distinct
Parties.PartyName [Vendor],
PayableInvoices.InvoiceNumber,
PayableInvoices.DueDate,
Assets.Alias,
Assets.Id AS AssetId,
Assets.UsageCondition,
Assets.Quantity,
CostTypes.Name,
AssetValueHistories.Cost_Amount [Cost],
Assets.CurrencyCode [Currency],
Locations.AddressLine1+'' ''+Locations.City+'' ''+ISNULL(EntityResourceForState.Value,States.LongName)+'' ''+Locations.PostalCode+'' ''+ISNULL(EntityResourceForCountry.Value,Countries.ShortName) [Location],
Assets.Description,
DisbursementRequests.Id [DisbursementRequestId],
LegalEntities.LegalEntityNumber
From DisbursementRequests
Join LegalEntities On LegalEntities.Id = DisbursementRequests.LegalEntityId
Join DisbursementRequestPayables On DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
Join Payables On Payables.Id = DisbursementRequestPayables.PayableId
Join PayableInvoices On PayableInvoices.Id = Payables.EntityId
And Payables.EntityType = ''PI''
Join Parties On Parties.Id = PayableInvoices.VendorId
Join PayableInvoiceAssets On PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
And PayableInvoiceAssets.IsActive = 1
Join assets On assets.Id = PayableInvoiceAssets.AssetId
Join AssetTypes On AssetTypes.Id = Assets.TypeId
Join CostTypes On CostTypes.Id = AssetTypes.CostTypeId
Join AssetValueHistories On AssetValueHistories.AssetId = Assets.Id
And SourceModule = ''PayableInvoice''
And IsAccounted = 1 And IsSchedule = 1 And IsLessorOwned = 1
left join AssetLocations On AssetLocations.AssetId = PayableInvoiceAssets.AssetId
And AssetLocations.IsActive = 1
Join Locations On Locations.Id = AssetLocations.LocationId
Join States On States.Id = Locations.StateId
And States.IsActive = 1
Join Countries on Countries.Id = States.CountryId
left join EntityResources EntityResourceForState
On States.Id = EntityResourceForState.EntityId
And EntityResourceForState.EntityType = ''State''
And EntityResourceForState.Name = ''ShortName''
And EntityResourceForState.Culture = @Culture
left join EntityResources EntityResourceForCountry
On Countries.Id = EntityResourceForCountry.EntityId
And EntityResourceForCountry.EntityType = ''Country''
And EntityResourceForCountry.Name = ''ShortName''
And EntityResourceForCountry.Culture = @Culture
Where DisbursementRequests.Id = @DisbursementId AND AssetLocations.IsCurrent = 1
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM (SELECT DISTINCT AssetId FROM CTE_AssetDetails) A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT A.*,ASN.SerialNumber FROM CTE_AssetDetails A
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON A.AssetId = ASN.AssetId 
'
EXEC sp_executesql @sql, N'
@DisbursementId BigInt,
@Culture NVARCHAR(10),
@AssetMultipleSerialNumberType NVARCHAR(10)',
@DisbursementId,
@Culture,
@AssetMultipleSerialNumberType
end

GO
