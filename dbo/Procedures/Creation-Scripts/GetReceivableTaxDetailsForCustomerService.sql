SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceivableTaxDetailsForCustomerService]
(
@ReceivableInvoiceId BIGINT,
@ContractId BIGINT = NULL
)
AS
SET NOCOUNT ON
BEGIN
;With CTEJurisdiction As
(
Select Ext.Id [Id],  Ext.Description [JurisdictionLevel], TaxAuthorityConfigs.Description [Jurisdiction] from TaxAuthorityConfigs
INNER JOIN TaxAuthorityConfigs Ext ON Ext.TaxJurisdictionLevelId = TaxAuthorityConfigs.Id
UNION
SELECT Id , Description , Description FROM TaxAuthorityConfigs
WHERE TaxJurisdictionLevelId IS NULL
)
SELECT CTEJurisdiction.[JurisdictionLevel],
Case
WHEN CTEJurisdiction.[JurisdictionLevel] = 'Country' THEN Countries.LongName
WHEN CTEJurisdiction.[JurisdictionLevel] = 'State' THEN States.LongName
WHEN CTEJurisdiction.[JurisdictionLevel] = 'County' THEN Locations.Division
WHEN CTEJurisdiction.[JurisdictionLevel] = 'County Transit' THEN Locations.Division
WHEN CTEJurisdiction.[JurisdictionLevel] = 'City' THEN Locations.City
WHEN CTEJurisdiction.[JurisdictionLevel] = 'City Transit' THEN Locations.Division
WHEN CTEJurisdiction.[JurisdictionLevel] = 'Province' THEN States.LongName
End Jurisdiction,
ReceivableTaxImpositions.AppliedTaxRate,
ReceivableTaxImpositions.ExternalTaxImpositionType,
SUM(ReceivableTaxImpositions.Amount_Amount) [Amount],
ReceivableTaxImpositions.Amount_Currency [Currency]
FROM
ReceivableInvoiceDetails
INNER JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId  = ReceivableDetails.Id
INNER JOIN Receivables ON Receivables.Id = ReceivableDetails.ReceivableId
INNER JOIN ReceivableTaxDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId
INNER JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id
INNER JOIN ReceivableTaxImpositions ON ReceivableTaxImpositions.ReceivableTaxDetailId = ReceivableTaxDetails.Id
INNER JOIN CTEJurisdiction ON ReceivableTaxImpositions.ExternalJurisdictionLevelId = CTEJurisdiction.Id
LEFT JOIN Locations ON ReceivableTaxDetails.LocationId = Locations.Id
LEFT JOIN States ON Locations.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
WHERE ReceivableTaxImpositions.IsActive = 1 And ReceivableTaxImpositions.AppliedTaxRate <> 0
AND ReceivableTaxDetails.IsActive = 1
AND ReceivableInvoiceDetails.IsActive = 1
AND ReceivableTaxes.IsActive = 1
AND ReceivableInvoiceDetails.ReceivableInvoiceId = @ReceivableInvoiceId
AND (@ContractId IS NULL OR (Receivables.EntityType = 'CT' AND Receivables.EntityId = @ContractId))
GROUP BY
Locations.StateId,
CTEJurisdiction.Id,
CTEJurisdiction.[JurisdictionLevel],
ReceivableTaxImpositions.AppliedTaxRate,
ReceivableTaxImpositions.ExternalTaxImpositionType,
ReceivableTaxImpositions.Amount_Currency,
Countries.LongName,
States.LongName,
Locations.Division,
Locations.City
END


GO
