CREATE TYPE [dbo].[NonAccrualIncomeReclassInput] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [date] NULL,
	[PayoffLeaseFinanceId] [bigint] NULL
)
GO
