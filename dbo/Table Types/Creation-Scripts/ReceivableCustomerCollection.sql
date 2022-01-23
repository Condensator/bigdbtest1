CREATE TYPE [dbo].[ReceivableCustomerCollection] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[DueDate] [date] NULL,
	[CustomerId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[TaxLevel] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO
