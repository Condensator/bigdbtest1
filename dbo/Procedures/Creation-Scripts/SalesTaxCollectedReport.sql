SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SalesTaxCollectedReport]
(
@FromDueDate DATETIME = NULL,
@ToDueDate DATETIME =  NULL,
@EntityType NVARCHAR(28) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Declare @FinalSQL nvarchar(Max)
Set @FinalSQL = '
;With CTEBase As
(
SELECT
receivable.EntityType
,receivable.EntityId
,receivable.Id AS ReceivableID
,receivable.DueDate
,receipt.ReceivedDate
,receipt.Id AS ReceiptID
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  1 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CountryTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  2 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end StateTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  5 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CountyTaxRate
,CASE WHEN receivableTaxImposition.ExternalJurisdictionLevelId =  11 then receivableTaxImposition.AppliedTaxRate ELSE 0.00 end CityTaxRate
,receivable.TotalAmount_Amount AS ReceivableAmount
,receivable.TotalAmount_Currency AS ReceivableAmountCurrency
,receivableTaxImposition.Amount_Amount AS TaxAmount
,receivableTaxImposition.Amount_Currency AS TaxAmountCurrency
,RAreceivableTaxImposition.AmountPosted_Amount AS AmountCollected
,RAreceivableTaxImposition.AmountPosted_Currency AS AmountCollectedCurrency
,receivable.ReceivableCodeId
,receivableTaxImposition.ExternalJurisdictionLevelId
,receivableTaxDetail.LocationId
,receivable.LegalEntityId
,receivable.CustomerId
FROM Receipts receipt
JOIN ReceiptApplications receiptApplication ON receipt.Id = receiptApplication.ReceiptId AND receipt.Status =''Posted''
JOIN ReceiptApplicationReceivableTaxImpositions RAreceivableTaxImposition ON receiptApplication.Id = RAreceivableTaxImposition.ReceiptApplicationId and RAreceivableTaxImposition.IsActive = 1
JOIN ReceivableTaxImpositions receivableTaxImposition ON RAreceivableTaxImposition.ReceivableTaxImpositionId = receivableTaxImposition.Id and receivableTaxImposition.IsActive = 1
JOIN ReceivableTaxDetails receivableTaxDetail ON receivableTaxImposition.ReceivableTaxDetailId = receivableTaxDetail.Id and receivableTaxDetail.IsActive = 1
JOIN ReceivableDetails receivableDetail ON receivableTaxDetail.ReceivableDetailId = receivableDetail.Id and receivableDetail.IsActive = 1
JOIN Receivables receivable ON receivableDetail.ReceivableId = receivable.Id
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
,receivableType.Name AS ReceivableType
,Case	When base.EntityType=''CT'' THEN contract.SequenceNumber
When base.EntityType=''CU'' THEN party.PartyNumber
Else CONVERT(varchar(100), base.EntityId) End EntityId
,base.EntityType
,base.ReceivableID
,base.DueDate
,base.ReceivedDate
,base.ReceiptID
,base.CountryTaxRate
,base.StateTaxRate
,base.CountyTaxRate
,base.CityTaxRate
,base.ReceivableAmount
,base.ReceivableAmountCurrency
,base.TaxAmount
,base.TaxAmountCurrency
,base.AmountCollected
,base.AmountCollectedCurrency
FROM CTEBase base
JOIN ReceivableCodes receivableCode ON base.ReceivableCodeId = receivableCode.Id
JOIN ReceivableTypes receivableType ON receivableCode.ReceivableTypeId = receivableType.Id
JOIN Locations location ON base.LocationId = location.Id
JOIN States state ON location.StateId = state.Id
JOIN Countries country ON state.CountryId = country.Id
JOIN LegalEntities legalEntity ON base.LegalEntityId = legalEntity.Id
LEFT JOIN Contracts contract on base.EntityId = contract.Id And base.EntityType=''CT''
LEFT JOIN Customers customer on base.EntityId = customer.Id And base.EntityType=''CU''
LEFT JOIN Parties party ON base.CustomerId = party.Id
LEFT JOIN TaxAuthorityConfigs taxAuthorityConfig ON base.ExternalJurisdictionLevelId = taxAuthorityConfig.Id
LEFT JOIN EntityResources EntityResourceForState ON  EntityResourceForState.EntityId=state.Id
AND EntityResourceForState.EntityType=''State''
AND EntityResourceForState.Name=''ShortName''
AND EntityResourceForState.Culture=@Culture
LEFT JOIN EntityResources EntityResourceForCountry ON  EntityResourceForCountry.EntityId=country.Id
AND EntityResourceForCountry.EntityType=''Country''
AND EntityResourceForCountry.Name=''ShortName''
AND EntityResourceForCountry.Culture=@Culture
)
SELECT
Customer
,LegalEntityNumber
,EntityType
,EntityId
,ReceivableID
,ReceivableType
,DueDate
,ReceivedDate
,ReceiptID
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
,SUM(AmountCollected) AmountCollected
,AmountCollectedCurrency
FROM CTE_Header
GROUP BY Customer
,LegalEntityNumber
,EntityType
,EntityId
,ReceivableID
,ReceivableType
,DueDate
,ReceivedDate
,ReceiptID
,Country
,State
,County
,City
,LocationCode
,ReceivableAmount
,ReceivableAmountCurrency
,TaxAmountCurrency
,AmountCollectedCurrency
'
Declare @WhereCondition nvarchar(Max)
Set @WhereCondition = ''
If @EntityType Is Not NULL AND @EntityType <> '_'
Begin
If Len(@WhereCondition) = 0 Set @WhereCondition = ' Where ' Else  Set @WhereCondition = @WhereCondition + ' And '
Set @WhereCondition = @WhereCondition + ' receivable.EntityType = @EntityType '
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
exec sp_executesql @FinalSQL,
N'@FromDueDate DateTime, @ToDueDate DateTime, @EntityType nvarchar(28),@Culture nvarchar(10) ',
@FromDueDate, @ToDueDate, @EntityType, @Culture
END

GO
