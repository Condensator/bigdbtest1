CREATE TYPE [dbo].[TaxBasisLocationParam] AS TABLE(
	[LineItemId] [varchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerAssetLocationId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[TaxBasisType] [varchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO
