SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[CreateLWDefaultConstraints]
AS
Begin
-- Adding constraints to restrict updating balance above amount or below 0.

-- Receivables
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_Receivables_TotalBalance')
ALTER TABLE [dbo].[Receivables]  DROP  CONSTRAINT [CK_Receivables_TotalBalance] 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_Receivables_TotalEffectiveBalance')
ALTER TABLE [dbo].[Receivables]  DROP  CONSTRAINT [CK_Receivables_TotalEffectiveBalance] 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='DF_Receivables_ReceivableTaxType')
ALTER TABLE [dbo].[Receivables]  DROP  CONSTRAINT [DF_Receivables_ReceivableTaxType] 


-- Receivable Details
IF  EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableDetails_Balance')
ALTER TABLE [dbo].[ReceivableDetails]  DROP  CONSTRAINT [CK_ReceivableDetails_Balance]  

IF  EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableDetails_EffectiveBalance')
ALTER TABLE [dbo].[ReceivableDetails]  DROP  CONSTRAINT [CK_ReceivableDetails_EffectiveBalance]  


-- Receivable Invoice Details
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableInvoiceDetails_Balance')
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  DROP  CONSTRAINT [CK_ReceivableInvoiceDetails_Balance] 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableInvoiceDetails_EffectiveBalance')
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  DROP  CONSTRAINT [CK_ReceivableInvoiceDetails_EffectiveBalance] 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableInvoiceDetails_TaxBalance')
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  DROP  CONSTRAINT [CK_ReceivableInvoiceDetails_TaxBalance] 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableInvoiceDetails_EffectiveTaxBalance')
ALTER TABLE [dbo].[ReceivableInvoiceDetails]  DROP  CONSTRAINT [CK_ReceivableInvoiceDetails_EffectiveTaxBalance] 


-- Receivable Taxs
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxes_Balance')
ALTER TABLE [dbo].[ReceivableTaxes]  DROP  CONSTRAINT [CK_ReceivableTaxes_Balance] 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxes_EffectiveBalance')
ALTER TABLE [dbo].[ReceivableTaxes]  DROP  CONSTRAINT [CK_ReceivableTaxes_EffectiveBalance] 


-- Receivable Tax Details
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxDetails_Balance')
ALTER TABLE [dbo].[ReceivableTaxDetails]  DROP  CONSTRAINT [CK_ReceivableTaxDetails_Balance] 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxDetails_EffectiveBalance')
ALTER TABLE [dbo].[ReceivableTaxDetails]  DROP  CONSTRAINT [CK_ReceivableTaxDetails_EffectiveBalance] 


-- Receivable Tax Impositions
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxImpositions_Balance')
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [CK_ReceivableTaxImpositions_Balance] CHECK (([Balance_Amount]>=(0) AND [Balance_Amount]<=[Amount_Amount]) OR ([Balance_Amount]<=(0) AND [Balance_Amount]>=[Amount_Amount]))


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME='CK_ReceivableTaxImpositions_EffectiveBalance')
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [CK_ReceivableTaxImpositions_EffectiveBalance] CHECK (([EffectiveBalance_Amount]>=(0) AND [EffectiveBalance_Amount]<=[Amount_Amount]) OR ([EffectiveBalance_Amount]<=(0) AND [EffectiveBalance_Amount]>=[Amount_Amount]))

ALTER TABLE ReceivableSKUs NOCHECK CONSTRAINT EReceivableDetail_ReceivableSKUs
ALTER TABLE ReceivableSKUs NOCHECK CONSTRAINT EReceivableSKU_AssetSKU
 
ALTER TABLE LeaseAssetSkus NOCHECK CONSTRAINT ELeaseAsset_LeaseAssetSKUs
ALTER TABLE LeaseAssetSkus NOCHECK CONSTRAINT ELeaseAssetSKU_AssetSKU
 
ALTER TABLE ReceiptApplicationReceivableTaxImpositions NOCHECK CONSTRAINT EReceiptApplication_ReceiptApplicationReceivableTaxImpositions
ALTER TABLE ReceiptApplicationReceivableTaxImpositions NOCHECK CONSTRAINT EReceiptApplicationReceivableTaxImposition_ReceivableTaxImposition

ALTER TABLE ReceivableDetails NOCHECK CONSTRAINT EReceivableDetail_AdjustmentBasisReceivableDetail

ALTER TABLE AssetSKUs NOCHECK CONSTRAINT EAsset_AssetSKUs

ALTER TABLE PayoffAssetSKUs NOCHECK CONSTRAINT EPayoffAsset_PayoffAssetSKUs
ALTER TABLE PayoffAssetSKUs NOCHECK CONSTRAINT EPayoffAssetSKU_LeaseAssetSKU

-- Adding default constraint to ReceivableTaxType column 
IF NOT EXISTS (SELECT 1 FROM SYS.DEFAULT_CONSTRAINTS WHERE NAME='DF_Receivables_ReceivableTaxType')
BEGIN 
	IF COL_LENGTH('Receivables','ReceivableTaxType') IS NOT NULL 
	BEGIN 
		UPDATE Receivables SET ReceivableTaxType = 'None' WHERE ReceivableTaxType IS NULL 
		
		ALTER TABLE [dbo].[Receivables] ADD CONSTRAINT [DF_Receivables_ReceivableTaxType] DEFAULT 'None' FOR ReceivableTaxType 
	END 
END

END

GO
