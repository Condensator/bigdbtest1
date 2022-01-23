SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TerminationProceedsReport]
(
@FromDate DATETIMEOFFSET=NULL,
@ToDate DATETIMEOFFSET=NULL,
@IsPurchasedForSale BIT = NULL,
@LegalEntityNumber NVARCHAR(30) = NULL,
@EntityType NVARCHAR(30) = NULL,
@FilterOption NVARCHAR(15) = NULL,
@FromAssetSaleTransactionNumber AS NVARCHAR(40) = NULL,
@ToAssetSaleTransactionNumber AS NVARCHAR(40) = NULL,
@FromSequenceNumber AS NVARCHAR(40) = NULL,
@ToSequenceNumber AS NVARCHAR(40) = NULL,
@EndUserSale NVARCHAR(15),
@AssetSale NVARCHAR(15),
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_TerminationInPayoff
AS
(
SELECT
Party.PartyNumber AS CustomerNumber
,Party.PartyName AS CustomerName
,Contract.SequenceNumber
,LeaseAsset.AssetId
,ISNULL(PayoffAsset.BuyoutAmount_Amount,0.00) AS SalePrice
,(ISNULL(Location.Name+ ', ',' ')  + ISNULL(Location.AddressLine1+ ', ',' ')  + ISNULL(Location.AddressLine2+ ', ', '  ')
+ ISNULL(Location.City+ ', ',' ')  + ISNULL(Location.Division+ ', ',' ')  + ISNULL(ISNULL(EntityResourceForState.Value,State.LongName)+ ', ', ' ')
+ ISNULL(ISNULL(EntityResourceForCountry.Value,Country.LongName)+ ', ', ' ') + ISNULL(Location.PostalCode,'  ')) AS [Ship To]
FROM Payoffs Payoff
JOIN PayoffAssets PayoffAsset ON Payoff.Id = PayoffAsset.PayoffId AND PayoffAsset.IsActive = 1 AND PayoffAsset.Status = 'Purchase'
JOIN LeaseAssets LeaseAsset ON PayoffAsset.LeaseAssetId = LeaseAsset.Id
JOIN LeaseFinances LeaseFinance ON Payoff.LeaseFinanceId = LeaseFinance.Id
JOIN Contracts Contract ON LeaseFinance.ContractId = Contract.Id
JOIN Assets Asset ON LeaseAsset.AssetId = Asset.Id
JOIN Parties Party ON Asset.CustomerId = Party.Id
LEFT JOIN AssetLocations AssetLocation ON Asset.Id = AssetLocation.AssetId AND AssetLocation.IsCurrent = 1
LEFT JOIN Locations Location ON AssetLocation.LocationId = Location.Id AND Location.IsActive = 1
LEFT JOIN States State ON Location.StateId = State.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=State.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='LongName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN Countries Country ON State.CountryId = Country.Id
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=Country.Id
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='LongName'
AND EntityResourceForCountry.Culture=@Culture
WHERE (@EntityType IS NULL OR @EntityType = 'Lease')
AND Payoff.Status = 'Activated'
AND (@FromDate IS NULL OR CAST(Payoff.PayoffEffectiveDate AS DATE) >= CAST(@FromDate AS DATE)
AND (@ToDate IS NULL OR CAST(Payoff.PayoffEffectiveDate AS DATE) <= CAST(@ToDate AS DATE)))
AND ((@ToSequenceNumber IS NULL
AND (@FromSequenceNumber IS NULL OR Contract.SequenceNumber = @FromSequenceNumber )) OR (@ToSequenceNumber IS NOT NULL
AND Contract.SequenceNumber >= @FromSequenceNumber
AND Contract.SequenceNumber <= @ToSequenceNumber ))
GROUP BY
Party.PartyNumber
,Party.PartyName
,Contract.SequenceNumber
,LeaseAsset.AssetId
,PayoffAsset.BuyoutAmount_Amount
,Location.Name
,Location.AddressLine1
,Location.AddressLine2
,Location.City
,Location.Division
,ISNULL(EntityResourceForState.Value,State.LongName)
,ISNULL(EntityResourceForCountry.Value,Country.LongName)
,Location.PostalCode
),
CTE_TerminationInAssetSale
AS
(
SELECT
Party.PartyNumber AS CustomerNumber
,Party.PartyName AS CustomerName
,AssetSale.TransactionNumber
,AssetSaleDetail.AssetId
,ISNULL(SUM(AssetSaleDetail.FairMarketValue_Amount),0.00) AS SalesPrice
,AssetSale.TaxLocationId
,(ISNULL(Location.Name+ ', ',' ')  + ISNULL(Location.AddressLine1+ ', ',' ')  + ISNULL(Location.AddressLine2+ ', ',' ')
+ ISNULL(Location.City+ ', ',' ')  + ISNULL(Location.Division+ ',',' ')  + ISNULL(ISNULL(EntityResourceForState.Value,State.LongName) + ', ' ,' ')
+ ISNULL(ISNULL(EntityResourceForCountry.Value,Country.LongName) +', ','  ') + ISNULL(Location.PostalCode,' ')) AS [Ship To]
FROM AssetSales AssetSale
JOIN AssetSaleDetails AssetSaleDetail ON AssetSale.Id = AssetSaleDetail.AssetSaleId AND AssetSaleDetail.IsActive = 1
JOIN Parties Party ON AssetSale.BuyerId = Party.Id
LEFT JOIN Locations Location ON AssetSale.TaxLocationId = Location.Id AND Location.IsActive = 1
LEFT JOIN States State ON Location.StateId = State.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=State.Id
AND EntityResourceForState.EntityType='State'
AND EntityResourceForState.Name='LongName'
AND EntityResourceForState.Culture=@Culture
LEFT JOIN Countries Country ON State.CountryId = Country.Id
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=Country.Id
AND EntityResourceForCountry.EntityType='Country'
AND EntityResourceForCountry.Name='LongName'
AND EntityResourceForCountry.Culture=@Culture
WHERE  (@EntityType IS NULL OR @EntityType = 'AssetSale')
AND  AssetSale.Status = 'Completed'
AND (@FromDate IS NULL OR (CAST(AssetSale.TransactionDate AS DATE) >= CAST(@FromDate AS DATE) AND (@ToDate IS NULL OR CAST(AssetSale.TransactionDate AS DATE) <= CAST(@ToDate AS DATE))))
AND (( @ToAssetSaleTransactionNumber IS NULL
AND ( @FromAssetSaleTransactionNumber IS NULL
OR AssetSale.TransactionNumber = @FromAssetSaleTransactionNumber ))
OR (@ToAssetSaleTransactionNumber IS NOT NULL
AND AssetSale.TransactionNumber >= @FromAssetSaleTransactionNumber
AND AssetSale.TransactionNumber <= @ToAssetSaleTransactionNumber ))
GROUP BY
Party.PartyNumber
,Party.PartyName
,AssetSale.TransactionNumber
,AssetSaleDetail.AssetId
,AssetSale.TaxLocationId
,Location.Name
,Location.AddressLine1
,Location.AddressLine2
,Location.City
,Location.Division
,ISNULL(EntityResourceForState.Value,State.LongName)
,ISNULL(EntityResourceForCountry.Value,Country.LongName)
,Location.PostalCode
)
SELECT
(CASE WHEN AssetSale.TransactionNumber IS NULL THEN @EndUserSale ELSE @AssetSale END) AS [Transaction Type],
ISNULL(Payoff.SequenceNumber, AssetSale.TransactionNumber) AS [Entity ID],
ISNULL(Payoff.CustomerName, AssetSale.CustomerName) AS Customer,
ISNULL(Payoff.CustomerNumber, AssetSale.CustomerNumber) AS CustomerNumber,
(CASE WHEN TaxDepEntities.IsActive = 1 THEN TaxDepTemplateDetails.TaxBook END) AS TaxBook,
Assets.Id AS [Asset ID],
(CASE WHEN TaxDepEntities.IsActive = 1 THEN TaxDepTemplates.Name END) AS [Tax Template],
Assets.Description,
ISNULL(Payoff.[Ship To], AssetSale.[Ship To]) AS [Ship To],
(CASE WHEN TaxDepEntities.IsActive = 1 THEN 'Yes' ELSE 'No' END) AS [Is Tax Depreciable],
CAST(Assets.InServiceDate AS DATE) AS [Date Placed In Service],
(CASE WHEN TaxDepEntities.IsActive = 1 THEN CAST(TaxDepEntities.TerminationDate AS DATE) END) AS [Termination Date],
(CASE WHEN TaxDepEntities.IsActive = 1 THEN ISNULL(SUM(TaxDepAmortizationDetails.DepreciationAmount_Amount),0.00) ELSE 0.00 END) AS [Accumulated Depreciation],
ISNULL(ISNULL(Payoff.SalePrice, AssetSale.SalesPrice),0.00) AS [Sales Price],
ISNULL(AssetSale.SalesPrice,0.00) AS [Asset Sale Sales Price],
ISNULL(Payoff.SalePrice,0.00) AS [End User Sale Sales Price],
LegalEntities.LegalEntityNumber,
(CASE WHEN Assets.IsSaleLeaseback = 1 THEN 'Yes' ELSE 'No' END) AS [Is Purchased For Sale],
ISNULL(TaxDepEntities.TaxBasisAmount_Amount,0.00) TaxDepreciationCostBasis,
CurrencyCodes.ISO AS Currency
FROM Assets
LEFT JOIN CTE_TerminationInAssetSale AssetSale  ON Assets.Id = AssetSale.AssetId
LEFT JOIN CTE_TerminationInPayoff Payoff ON Assets.Id = Payoff.AssetId
LEFT JOIN TaxDepEntities ON TaxDepEntities.AssetId = Assets.Id
LEFT JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
LEFT JOIN Currencies ON LegalEntities.CurrencyId = Currencies.Id
LEFT JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
LEFT JOIN TaxDepTemplates ON TaxDepEntities.TaxDepTemplateId = TaxDepTemplates.Id AND TaxDepTemplates.IsActive = 1 AND TaxDepEntities.IsActive = 1
LEFT JOIN TaxDepTemplateDetails ON TaxDepTemplates.Id = TaxDepTemplateDetails.TaxDepTemplateId
LEFT JOIN TaxDepAmortizations ON TaxDepEntities.Id = TaxDepAmortizations.TaxDepEntityId AND TaxDepAmortizations.IsActive = 1 AND TaxDepAmortizations.TaxDepreciationTemplateId = TaxDepTemplates.Id
LEFT JOIN TaxDepAmortizationDetails ON TaxDepAmortizations.Id = TaxDepAmortizationDetails.TaxDepAmortizationId AND TaxDepAmortizationDetails.TaxDepreciationTemplateDetailId = TaxDepTemplateDetails.Id
AND
TaxDepAmortizationDetails.IsSchedule = 1
WHERE (@LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber = @LegalEntityNumber)
AND (Assets.Id = AssetSale.AssetId OR Assets.Id = Payoff.AssetId)
--AND (TaxDepEntities.Id IS NOT NULL AND TaxDepEntities.FXTaxBasisAmount_Currency!=TaxDepEntities.TaxBasisAmount_Currency)
-- AND Assets.Id = 189131699 --TODO Testing
AND (@IsPurchasedForSale = 0 OR Assets.IsSaleLeaseback = @IsPurchasedForSale)
AND (TaxDepAmortizationDetails.DepreciationAmount_Currency IS NULL
OR CurrencyCodes.ISO IS NULL OR TaxDepAmortizationDetails.DepreciationAmount_Currency = CurrencyCodes.ISO)
GROUP BY
AssetSale.CustomerName
,Payoff.CustomerName
,AssetSale.CustomerNumber
,Payoff.CustomerNumber
,Payoff.SequenceNumber
,AssetSale.TransactionNumber
,Payoff.SalePrice
,AssetSale.SalesPrice
,Payoff.[Ship To]
,AssetSale.[Ship To]
,Assets.Id
,Assets.InServiceDate
,TaxDepEntities.TerminationDate
,LegalEntities.LegalEntityNumber
,Assets.Description
,TaxDepTemplates.Name
,LegalEntities.LegalEntityNumber
,Assets.IsSaleLeaseback
,TaxDepEntities.IsActive
,TaxDepTemplateDetails.TaxBook
,TaxDepEntities.TaxBasisAmount_Amount
,CurrencyCodes.ISO
END

GO
