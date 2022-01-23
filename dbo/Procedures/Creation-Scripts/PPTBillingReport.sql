SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PPTBillingReport]
(
@SequenceNumber NVARCHAR(MAX) = null,
@IsSummary BIT = 0,
@StateShortName NVARCHAR(MAX) = null,
@Culture NVARCHAR(10)
)
AS
BEGIN
SELECT
Parties.PartyNumber [CustomerNumber]
,Assets.Id [AssetId]
,Assets.Description [AssetDescription]
,Parties.PartyName [CustomerName]
,Contracts.SequenceNumber [ContractSequenceNumber]
,ReceivableInvoices.Number [InvoiceNumber]
,ReceivableInvoices.Duedate [InvoiceDueDate]
,ISNULL(EntityResourceForState.Value,States.ShortName) [StateShortName]
,PropertyTaxes.TaxDistrict
,ReceivableInvoiceDetails.InvoiceAmount_Amount [PropertyTaxAmount]
,ReceivableInvoiceDetails.InvoiceTaxAmount_Amount  [TaxAmount]
,ReceivableInvoiceDetails.InvoiceAmount_Currency [PropertyTaxCurrency]
,ReceivableInvoiceDetails.InvoiceTaxAmount_Currency [TaxCurrency]
,CASE WHEN Assets.PropertyTaxReportCodeId IS NULL THEN Assets.PropertyTaxResponsibility ELSE ISNULL(EntityResourceForPropertyTaxReportCodeConfig.Value,PropertyTaxReportCodeConfigs.Code) END [TaxDescription]
FROM ReceivableInvoices
INNER JOIN ReceivableInvoiceDetails on ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
INNER JOIN ReceivableDetails on ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
INNER JOIN Assets on Assets.Id = ReceivableDetails.AssetId
INNER JOIN Receivables on Receivables.Id = ReceivableDetails.ReceivableId
INNER JOIN PropertyTaxes on PropertyTaxes.PropTaxReceivableId = Receivables.Id
INNER JOIN Contracts on Receivables.EntityId = Contracts.Id AND Receivables.EntityType = 'CT'
INNER JOIN Parties on ReceivableInvoices.CustomerId = Parties.Id
INNER JOIN States on States.Id = PropertyTaxes.StateId
INNER JOIN PropertyTaxReportCodeConfigs on Assets.PropertyTaxReportCodeId = PropertyTaxReportCodeConfigs.Id
LEFT JOIN EntityResources EntityResourceForPropertyTaxReportCodeConfig
ON PropertyTaxReportCodeConfigs.Id = EntityResourceForPropertyTaxReportCodeConfig.EntityId
AND EntityResourceForPropertyTaxReportCodeConfig.EntityType = 'PropertyTaxReportCodeConfig'
AND EntityResourceForPropertyTaxReportCodeConfig.Name = 'Code'
AND EntityResourceForPropertyTaxReportCodeConfig.Culture = @Culture
LEFT JOIN EntityResources EntityResourceForState
ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE Contracts.SequenceNumber = @SequenceNumber
AND (@StateShortName IS NULL OR States.ShortName = @StateShortName)
AND ReceivableInvoices.IsActive = 1
AND Receivables.IsActive = 1
END

GO
