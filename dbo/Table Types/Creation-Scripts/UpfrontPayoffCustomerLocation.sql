CREATE TYPE [dbo].[UpfrontPayoffCustomerLocation] AS TABLE(
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[QuoteNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL
)
GO
