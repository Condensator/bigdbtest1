CREATE TYPE [dbo].[BookDepreciationDataCacheInput] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[TerminationDate] [date] NOT NULL
)
GO
