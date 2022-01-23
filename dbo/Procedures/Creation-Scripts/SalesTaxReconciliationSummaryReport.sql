SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SalesTaxReconciliationSummaryReport]
(
@CustomerID NVarChar(40) ,
@StateId Int,
@FromDate DateTime,
@ToDate DateTime,
@CommaSeparatedLegalEntityIds Nvarchar(max),
@Culture NVARCHAR(10)
)
As
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON
Declare @ReconciliationString nvarchar(Max)
Set @ReconciliationString = '
WITH CTEHeader
AS
(
SELECT
ReceivableTaxImpositions.Id ReceivableTaxImpositionId,
ReceivableTaxDetails.Id ReceivableTaxDetailId,
ReceivableTaxes.Id ReceivableTaxId,
TaxAuthorityConfigs.Id TaxAuthorityId,
ReceivableTaxDetails.Revenue_Amount [TotalReceipts],
ReceivableTaxDetails.Revenue_Currency [TaxDetailsCurrency],
Locations.StateId StateId,
Locations.Division County,
Locations.City,
(CASE TaxAuthorityConfigs.Id
WHEN 1 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [CountryTaxRate],
(CASE TaxAuthorityConfigs.Id
WHEN 2 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [StateTaxRate],
(CASE TaxAuthorityConfigs.Id
WHEN 5 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [CounyTaxRate],
(CASE TaxAuthorityConfigs.Id
WHEN 8 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [CounyTransitTaxRate],
(CASE TaxAuthorityConfigs.Id
WHEN 11 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [CityTaxRate],
(CASE TaxAuthorityConfigs.Id
WHEN 15 THEN ReceivableTaxImpositions.AppliedTaxRate
ELSE 0.00
END) [CityTransitTaxRate],
(CASE
WHEN ABS(ReceivableTaxImpositions.ExemptionAmount_Amount) > ABS(ReceivableTaxDetails.Revenue_Amount) THEN ReceivableTaxDetails.Revenue_Amount
ELSE ReceivableTaxImpositions.ExemptionAmount_Amount
END) [ExemptionAmount],
ReceivableTaxImpositions.Amount_Amount Amount,
ReceivableInvoices.Number InvoiceNumber,
ReceivableInvoices.CancellationDate
FROM ReceivableTaxDetails
INNER JOIN ReceivableTaxes
ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id
AND ReceivableTaxDetails.IsActive = 1
INNER JOIN ReceivableTaxImpositions
ON ReceivableTaxDetails.id = ReceivableTaxImpositions.ReceivableTaxDetailId
AND ReceivableTaxImpositions.IsActive = 1
INNER JOIN TaxAuthorityConfigs
ON ReceivableTaxImpositions.ExternalJurisdictionLevelId = TaxAuthorityConfigs.Id
INNER JOIN Receivables
ON ReceivableTaxes.ReceivableId = Receivables.Id
AND Receivables.IsDummy = 0
AND Receivables.IsActive = 1
INNER JOIN Locations
ON ReceivableTaxDetails.LocationId = Locations.Id
INNER JOIN LegalEntities
ON Receivables.LegalEntityId = LegalEntities.ID
LEFT JOIN ReceivableInvoiceDetails
ON ReceivableTaxDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId
AND ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableInvoiceDetails.IsActive = 1
LEFT JOIN ReceivableInvoices
ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
WHERECONDITION),
CTEDetail
AS (SELECT
CTEHeader.ReceivableTaxId,
CTEHeader.TaxAuthorityID,
CTEHeader.TotalReceipts,
CTEHeader.TaxDetailsCurrency,
SUM(CTEHeader.CountryTaxRate) CountryTaxRate,
CTEHeader.StateID,
SUM(CTEHeader.StateTaxRate) StateTaxRate,
CTEHeader.County,
SUM(CTEHeader.CounyTaxRate) CounyTaxRate,
SUM(CTEHeader.CounyTransitTaxRate) CounyTransitTaxRate,
CTEHeader.City,
SUM(CTEHeader.CityTaxRate) CityTaxRate,
SUM(CTEHeader.CityTransitTaxRate) CityTransitTaxRate,
MIN(CTEHeader.ExemptionAmount) [ExemptReceipts],
SUM(CTEHeader.Amount) [TotalTax]
FROM CTEHeader
WHERE (CTEHeader.CancellationDate is  null) -- Filtering records not on cancelled Invoices
GROUP BY	CTEHeader.ReceivableTaxId,
CTEHeader.TotalReceipts,
CTEHeader.TaxDetailsCurrency,
CTEHeader.TaxAuthorityID,
CTEHeader.StateID,
CTEHeader.County,
CTEHeader.City),
CTEBase
AS (SELECT
CTEDetail.ReceivableTaxId,
Countries.Id CountryID,
ISNULL(EntityResourceForCountry.Value,Countries.LongName) CountryName,
ISNULL(EntityResourceForState.Value,States.LongName) StateName,
SUM(CTEDetail.CountryTaxRate) CountryTaxRate,
CTEDetail.StateId,
SUM(CTEDetail.StateTaxRate) StateTaxRate,
CTEDetail.County,
SUM(CTEDetail.CounyTaxRate) CounyTaxRate,
SUM(CTEDetail.CounyTransitTaxRate) CounyTransitTaxRate,
CTEDetail.City,
SUM(CTEDetail.CityTaxRate) CityTaxRate,
SUM(CTEDetail.CityTransitTaxRate) CityTransitTaxRate,
CTEDetail.TotalReceipts [TotalReceipts],
MIN(CTEDetail.ExemptReceipts) [ExemptReceipts],
MAX(CTEDetail.TotalReceipts - CTEDetail.ExemptReceipts) [TaxableReceipts],
SUM(CTEDetail.TotalTax) [TotalTax],
CTEDetail.TaxDetailsCurrency
FROM CTEDetail
INNER JOIN States
ON CTEDetail.StateId = States.Id
INNER JOIN Countries
ON States.CountryId = Countries.Id
LEFT JOIN EntityResources EntityResourceForCountry
ON EntityResourceForCountry.EntityId=Countries.Id
AND EntityResourceForCountry.EntityType=''Country''
AND EntityResourceForCountry.Name=''LongName''
AND EntityResourceForCountry.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForState
ON  EntityResourceForState.EntityId=States.Id
AND EntityResourceForState.EntityType=''State''
AND EntityResourceForState.Name=''LongName''
AND EntityResourceForState.Culture=@Culture
GROUP BY	CTEDetail.ReceivableTaxID,
Countries.Id,
ISNULL(EntityResourceForCountry.Value,Countries.LongName),
CTEDetail.StateId,
ISNULL(EntityResourceForState.Value,States.LongName),
CTEDetail.County,
CTEDetail.City,
CTEDetail.TotalReceipts,
CTEDetail.TaxDetailsCurrency)
SELECT
CTEBase.CountryID,
CTEBase.CountryName,
CTEBase.CountryTaxRate,
CTEBase.StateId,
CTEBase.StateName,
CTEBase.StateTaxRate,
CTEBase.County,
CTEBase.CounyTaxRate,
CTEBase.CounyTransitTaxRate,
CTEBase.City,
CTEBase.CityTaxRate,
CTEBase.CityTransitTaxRate,
Sum(CTEBase.TotalReceipts) [TotalReceipts],
Sum(CTEBase.ExemptReceipts) [ExemptReceipts],
Sum(CTEBase.TotalReceipts - CTEBase.ExemptReceipts) [TaxableReceipts],
Sum(CTEBase.TotalTax) [TotalTax] ,
CTEBase.TaxDetailsCurrency
from  CTEBase
Group By
CTEBase.CountryID,
CTEBase.CountryName,
CTEBase.CountryTaxRate,
CTEBase.StateId,
CTEBase.StateName,
CTEBase.StateTaxRate,
CTEBase.County,
CTEBase.CounyTaxRate,
CTEBase.CounyTransitTaxRate,
CTEBase.City,
CTEBase.CityTaxRate,
CTEBase.CityTransitTaxRate,
CTEBase.TaxDetailsCurrency'
Declare @WhereCondition nvarchar(Max)
Set @WhereCondition = ''
If @CustomerId Is Not Null Or @CustomerId <> ''
begin
Set @WhereCondition = @WhereCondition + ' Where Receivables.CustomerID = @CustomerId '
end
If @StateId Is Not Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' Locations.StateId = @StateId '
End
If @FromDate Is Not Null And @ToDate Is Not Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' (Receivables.DueDate Between @FromDate And @ToDate)  '
End
Else If @FromDate Is Not Null And @ToDate Is Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' (Receivables.DueDate = @FromDate) '
End
IF LEN(@CommaSeparatedLegalEntityIds) > 0
BEGIN
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
SET @WhereCondition = @WhereCondition + ' Receivables.LegalEntityId IN (' + @CommaSeparatedLegalEntityIds + ') '
END
If Len(@WhereCondition) <> 0
Set @ReconciliationString = Replace(@ReconciliationString, 'WHERECONDITION', @WhereCondition)
Else
Set @ReconciliationString = Replace(@ReconciliationString, 'WHERECONDITION', '')
exec sp_executesql @ReconciliationString,
N'@CustomerId NVarChar(40), @StateId Int, @FromDate DateTime, @ToDate DateTime,@Culture NVARCHAR(10)',
@CustomerId, @StateId, @FromDate, @ToDate,@Culture

GO
