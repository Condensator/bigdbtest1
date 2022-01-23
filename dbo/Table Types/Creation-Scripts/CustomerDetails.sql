CREATE TYPE [dbo].[CustomerDetails] AS TABLE(
	[CustomerId] [bigint] NOT NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[InvoiceTransitDays] [int] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL
)
GO
