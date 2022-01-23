SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SalesTaxExceptionReport]
@LocationEffectiveDate DATETIME,
@AssetIds NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON
--DECLARE @LocationEffectiveDate DATETIME = GETDATE()
--DECLARE @AssetIds NVARCHAR(MAX) = '103262'
CREATE TABLE #AssetIds(AssetId INT)
INSERT INTO #AssetIds
SELECT * FROM ConvertCSVToBigIntTable(@AssetIds,',')
CREATE TABLE #TAX (ReceivableID BIGINT, DueDate DATETIME, ContractId INT, ReceivableTypeID TINYINT, AssetId BIGINT,LocationID INT, ChargeAmount DECIMAL(18,2),TaxAmount DECIMAL(18,2), TaxBalance DECIMAL(18,2), Currency NVARCHAR(10))
INSERT INTO #TAX
SELECT Receivables.Id [ReceivableId],Receivables.DueDate,Receivables.EntityId [ContractId],ReceivableCodes.ReceivableTypeId,ReceivableTaxDetails.AssetId,AssetLocations.LocationId,
SUM(ReceivableTaxDetails.Revenue_Amount) [Revenue_Amount],SUM(ReceivableTaxDetails.Amount_Amount) [TaxAmount],SUM(ReceivableTaxDetails.Balance_Amount) [TaxBalance], ReceivableTaxDetails.Revenue_Currency
FROM #AssetIds
JOIN ReceivableTaxDetails ON #AssetIds.AssetId = ReceivableTaxDetails.AssetId AND ReceivableTaxDetails.IsActive = 1
JOIN ReceivableTaxes ON ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId And ReceivableTaxes.IsActive = 1
JOIN Receivables ON ReceivableTaxes.ReceivableId = Receivables.Id AND Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate >= @LocationEffectiveDate
JOIN ReceivableCodes ON ReceivableCodes.Id = Receivables.ReceivableCodeId AND ReceivableCodes.IsActive = 1
JOIN AssetLocations ON AssetLocations.Id = ReceivableTaxDetails.AssetLocationId
GROUP BY Receivables.Id,Receivables.DueDate,Receivables.EntityId,ReceivableCodes.ReceivableTypeId,ReceivableTaxDetails.AssetId,AssetLocations.LocationId,ReceivableTaxDetails.Revenue_Currency
SELECT
#TAX.ReceivableId
,Parties.PartyName
,Parties.PartyNumber
,Contracts.SequenceNumber
,#TAX.AssetId
,ReceivableTypes.Name [ReceivableTypeName]
,#TAX.DueDate
,#TAX.ChargeAmount
,#TAX.TaxAmount
,#TAX.TaxBalance
,Locations.City
,States.ShortName [StateShortName]
,Locations.PostalCode
,Locations.TaxAreaId
,Countries.ShortName [CountryShortName]
,Locations.Division
,#TAX.Currency
FROM
#TAX
JOIN Contracts ON Contracts.Id = #TAX.ContractId
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
JOIN ReceivableTypes ON #TAX.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
JOIN Locations ON Locations.Id = #TAX.LocationID AND Locations.IsActive = 1
JOIN States ON Locations.StateId = States.Id AND States.IsActive = 1
JOIN Countries ON States.CountryId = Countries.Id
ORDER BY Contracts.SequenceNumber,ReceivableTypes.Name,#TAX.DueDate
DROP TABLE #AssetIds
DROP TABLE #TAX
END

GO
