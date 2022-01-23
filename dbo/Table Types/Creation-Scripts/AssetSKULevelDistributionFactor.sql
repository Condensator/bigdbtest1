CREATE TYPE [dbo].[AssetSKULevelDistributionFactor] AS TABLE(
	[AssetSKUId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[Factor] [decimal](38, 28) NOT NULL,
	[BillToId] [bigint] NULL,
	[RowNumber] [bigint] NULL,
	[MaturityPayment] [decimal](16, 2) NOT NULL,
	[IsLeaseComponent] [bit] NULL,
	[PreCapitalizationRent] [decimal](16, 2) NOT NULL
)
GO
