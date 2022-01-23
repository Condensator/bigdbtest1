SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SalesTaxBilledReport]
(
@FromDueDate DATETIME = NULL,
@ToDueDate DATETIME =  NULL,
@CountryID	INT = NULL,
@CountryName NVARCHAR(10) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Declare @FinalSQL nvarchar(Max)
Set @FinalSQL = '
;With CTE_Base AS
(
SELECT
receivable.EntityType
,receivable.EntityId
,receivableTax.ReceivableId
,receivable.DueDate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  1 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CountryTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  2 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end StateTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  5 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CountyTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  11 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CityTaxRate
,receivable.TotalAmount_Amount AS ReceivableAmount
,receivable.TotalAmount_Currency AS ReceivableAmountCurrency
,receivableTaxImposition.Amount_Amount AS TaxAmount
,receivableTaxImposition.Amount_Currency AS TaxAmountCurrency
,receivable.ReceivableCodeId
,receivableTaxDetail.LocationId
,receivable.LegalEntityId
,receivable.CustomerId
,receivableTaxImposition.ExternalJurisdictionLevelId
FROM
ReceivableTaxes receivableTax
JOIN ReceivableTaxDetails receivableTaxDetail on receivableTax.Id = receivableTaxDetail.ReceivableTaxId AND receivableTax.IsActive = 1 and receivableTaxDetail.IsActive = 1
JOIN ReceivableTaxImpositions receivableTaxImposition on receivableTaxDetail.Id = receivableTaxImposition.ReceivableTaxDetailId and receivableTaxImposition.IsActive = 1
JOIN Receivables receivable on receivableTax.ReceivableId = receivable.Id and receivable.IsActive = 1 AND receivable.IsDummy = 0
JOIN ReceivableDetails receivableDetail on receivableTaxDetail.ReceivableDetailId = receivableDetail.Id and receivableDetail.IsActive = 1
WHERECONDITION
),
CTE_Header AS
(
SELECT
party.PartyName AS Customer
,legalEntity.LegalEntityNumber
,ISNULL(EntityResourceForCountry.Value,country.ShortName) AS Country
,ISNULL(EntityResourceForState.Value,state.ShortName) AS State
,location.Division AS County
,location.City AS City
,location.Code AS LocationCode
,Case	When base.EntityType=''CT'' THEN contract.SequenceNumber
When base.EntityType=''CU'' THEN party.PartyNumber
Else CONVERT(varchar(100), base.EntityId) End EntityId
,base.EntityType
,base.ReceivableId
,receivableType.Name AS ReceivableType
,base.DueDate
,base.CountryTaxRate
,base.StateTaxRate
,base.CountyTaxRate
,base.CityTaxRate
,base.ReceivableAmount
,base.ReceivableAmountCurrency
,base.TaxAmount
,base.TaxAmountCurrency
FROM
CTE_Base base
JOIN ReceivableCodes receivableCode on base.ReceivableCodeId = receivableCode.Id
JOIN ReceivableTypes receivableType on receivableCode.ReceivableTypeId = receivableType.Id
JOIN Locations location on base.LocationId = location.Id
JOIN States state on location.StateId = state.Id
JOIN Countries country on state.CountryId = country.Id
JOIN LegalEntities legalEntity on base.LegalEntityId = legalEntity.Id
LEFT JOIN Contracts contract on base.EntityId = contract.Id And base.EntityType=''CT''
LEFT JOIN Customers customer on base.EntityId = customer.Id And base.EntityType=''CU''
LEFT JOIN Parties party on base.CustomerId = party.Id
LEFT JOIN TaxAuthorityConfigs taxAuthorityConfig on base.ExternalJurisdictionLevelId = taxAuthorityConfig.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=state.Id
AND EntityResourceForState.EntityType=''State''
AND EntityResourceForState.Name=''ShortName''
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry  ON EntityResourceForCountry.EntityId=country.Id
AND EntityResourceForCountry.EntityType=''Country''
AND EntityResourceForCountry.Name=''ShortName''
AND EntityResourceForCountry.Culture=@Culture
WHERE_COUNTRY_CONDITION
)
SELECT
Customer
,LegalEntityNumber
,EntityType
,EntityId
,ReceivableId
,ReceivableType
,DueDate
,Country
,State
,County
,City
,LocationCode
,SUM(CountryTaxRate) CountryTaxRate
,SUM(StateTaxRate) StateTaxRate
,SUM(CountyTaxRate) CountyTaxRate
,SUM(CityTaxRate) CityTaxRate
,ReceivableAmount
,ReceivableAmountCurrency
,SUM(TaxAmount) TaxAmount
,TaxAmountCurrency
FROM CTE_Header
GROUP BY
Customer
,LegalEntityNumber
,EntityType
,EntityId
,ReceivableId
,ReceivableType
,DueDate
,Country
,State
,County
,City
,LocationCode
,ReceivableAmount
,ReceivableAmountCurrency
,TaxAmountCurrency
'
Declare @WhereCondition nvarchar(Max)
Set @WhereCondition = ''
DECLARE @Where_Country_Condition NVARCHAR(MAX)
SET @Where_Country_Condition = ''
If @CountryID Is Not Null
Begin
If Len(@Where_Country_Condition) = 0 Set @Where_Country_Condition = ' Where ' Else  Set @Where_Country_Condition = @Where_Country_Condition + ' And '
Set @Where_Country_Condition = @Where_Country_Condition + ' country.Id = @CountryID '
End
If @FromDueDate Is Not Null And @ToDueDate Is Not Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' (receivable.DueDate Between @FromDueDate And @ToDueDate)  '
End
Else If @FromDueDate Is Not Null And @ToDueDate Is Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' (receivable.DueDate >= @FromDueDate) '
End
Else If @FromDueDate Is Null And @ToDueDate Is Not Null
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' (receivable.DueDate <= @ToDueDate) '
End
If Len(@WhereCondition) <> 0
Set @FinalSQL = Replace(@FinalSQL, 'WHERECONDITION', @WhereCondition)
Else
Set @FinalSQL = Replace(@FinalSQL, 'WHERECONDITION', '')
If Len(@Where_Country_Condition) <> 0
Set @FinalSQL = Replace(@FinalSQL, 'WHERE_COUNTRY_CONDITION', @Where_Country_Condition)
Else
Set @FinalSQL = Replace(@FinalSQL, 'WHERE_COUNTRY_CONDITION', '')
exec sp_executesql @FinalSQL,
N'@FromDueDate DateTime, @ToDueDate DateTime, @CountryID	int, @CountryName nvarchar(10),@Culture NVARCHAR(10) ',
@FromDueDate, @ToDueDate, @CountryID, @CountryName,@Culture
END

GO
