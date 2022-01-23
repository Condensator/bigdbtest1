CREATE TYPE [dbo].[PayoffDiscountingData] AS TABLE(
	[PayoffId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[NewLeaseFinanceId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [datetime] NOT NULL
)
GO
