CREATE TYPE [dbo].[ContractDetailsToFetchAISForDeferredRentals] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[CurrentLeaseFinanceId] [bigint] NOT NULL,
	[IncomeDateForDeferredRental] [datetime] NULL
)
GO
