CREATE TYPE [dbo].[AutoPayoff_DeferredTaxUpdateInput] AS TABLE(
	[ContractId] [bigint] NULL,
	[PayoffEffectiveDate] [date] NOT NULL
)
GO
