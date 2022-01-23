CREATE TYPE [dbo].[AutoPayoffInvoiceAddressInput] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL
)
GO
