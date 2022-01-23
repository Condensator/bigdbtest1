SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[ReceivableAllTaxView]
As
Select
Receivables.EntityId
,Receivables.EntityType
,Receivables.LegalEntityId
,Receivables.Id ReceivableId
,Receivables.DueDate
,ReceivableDetails.Id ReceivableDetailId
,ReceivableDetails.AssetId AssetId
,ReceivableDetails.Amount_Amount Amount
,ReceivableDetails.Balance_Amount Balance
,IsNull(ReceivableTaxDetails.Amount_Amount,0) TaxAmount
,IsNull(ReceivableTaxDetails.Balance_Amount,0) TaxBalance
,ReceivableTypes.Id ReceivableTypeId
,ReceivableTypes.Name ReceivableTypeName
,Receivables.IsDSL
,Receivables.IsDummy
,Receivables.IsGLPosted IsGLPosted
,IsNull(ReceivableTaxes.IsGLPosted,0) IsTaxGLPosted
,Receivables.SourceTable
,Receivables.SourceId
,ReceivableDetails.BilledStatus
,ReceivableInvoiceDetails.ReceivableInvoiceId InvoiceId
From Receivables
Join ReceivableDetails
On Receivables.Id = ReceivableDetails.ReceivableId
And Receivables.IsActive = 1
And ReceivableDetails.IsActive = 1
And ReceivableDetails.StopInvoicing = 0
And Receivables.IsServiced = 1
And ((Receivables.IsDummy = 1 AND Receivables.IsDSL = 1) OR (Receivables.IsDummy = 0 AND Receivables.IsDSL = 0))
Join ReceivableCodes
On Receivables.ReceivableCodeId = ReceivableCodes.Id
And ReceivableCodes.IsActive = 1
Join ReceivableTypes
On ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
And ReceivableTypes.IsActive = 1
Left Join ReceivableInvoiceDetails
On ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
And ReceivableInvoiceDetails.IsActive = 1
Left Join ReceivableInvoices
On ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
And ReceivableInvoices.IsActive = 1
Left Join ReceivableTaxes
On Receivables.Id = ReceivableTaxes.ReceivableId
And ReceivableTaxes.IsActive = 1
Left Join ReceivableTaxDetails
On ReceivableTaxes.Id = ReceivableTaxDetails.ReceivableTaxId
And ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId
And ReceivableTaxDetails.IsActive = 1

GO
