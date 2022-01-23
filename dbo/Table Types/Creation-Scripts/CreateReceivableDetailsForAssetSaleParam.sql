CREATE TYPE [dbo].[CreateReceivableDetailsForAssetSaleParam] AS TABLE(
	[ReceivableTempId] [bigint] NULL,
	[Amount] [decimal](16, 2) NULL,
	[Balance] [decimal](16, 2) NULL,
	[EffectiveBalance] [decimal](16, 2) NULL,
	[EffectiveBookBalance] [decimal](16, 2) NULL,
	[IsTaxAssessed] [bit] NULL,
	[IsActive] [bit] NULL,
	[BillToId] [bigint] NULL,
	[AssetId] [bigint] NULL
)
GO
