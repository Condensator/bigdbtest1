CREATE TYPE [dbo].[ContractTableType] AS TABLE(
	[ContractId] [bigint] NULL,
	[InvoiceDueDate] [date] NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableStartId] [bigint] NULL,
	[ReceivableEndId] [bigint] NULL
)
GO
