CREATE TYPE [dbo].[ReceivableAssetAmountDetails] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[CustomerCost] [decimal](16, 2) NOT NULL,
	[AssetExtendedPrice] [decimal](16, 2) NOT NULL
)
GO
