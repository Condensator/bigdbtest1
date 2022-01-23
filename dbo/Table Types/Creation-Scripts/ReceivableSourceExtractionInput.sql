CREATE TYPE [dbo].[ReceivableSourceExtractionInput] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[PayoffEffectiveDate] [datetime] NOT NULL,
	[IsAdvanceLease] [bit] NOT NULL
)
GO
