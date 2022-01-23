SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[CreateLWClusteredIndexes]
AS
Begin
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'SKUValueProportions' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='SKUValueProportions',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ReceivableSKUTaxReversalDetails' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ReceivableSKUTaxReversalDetails',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'CreditApplicationAdditionalCharges' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='CreditApplicationAdditionalCharges',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ReceivableInvoiceDetails' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ReceivableInvoiceDetails',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ReceiptApplicationGLJournals' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ReceiptApplicationGLJournals',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ReceiptGLJournals' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ReceiptGLJournals',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'TaxDepAmortizationDetails' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='TaxDepAmortizationDetails',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ProposalPaymentSchedules' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ProposalPaymentSchedules',@reqcolumn='Id'
END

If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ContractReportStatusHistory' AND b.name = 'Id')
BEGIN
EXEC ChangeClusteredIndex @table_name='ContractReportStatusHistory',@reqcolumn='Id'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'Payoffs' AND b.name = 'LeaseFinanceId')
BEGIN
EXEC ChangeClusteredIndex @table_name='Payoffs',@reqcolumn='LeaseFinanceId'
END
If NOT EXISTS(SELECT c.name FROM sys.indexes i INNER JOIN sys.index_columns a ON i.object_id = a.object_id AND i.index_id = a.index_id
			   INNER JOIN sys.columns b ON a.object_id = b.object_id AND a.column_id = b.column_id INNER JOIN sys.tables c ON i.object_id = c.object_id
			   WHERE i.type_desc = 'clustered' AND c.name = 'ReceiptApplicationReceivableDetails' AND b.name = 'ReceiptApplicationId')
BEGIN
EXEC ChangeClusteredIndex @table_name='ReceiptApplicationReceivableDetails',@reqcolumn='ReceiptApplicationId'
END
END

GO
