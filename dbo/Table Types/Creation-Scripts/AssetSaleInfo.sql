CREATE TYPE [dbo].[AssetSaleInfo] AS TABLE(
	[AssetId] [bigint] NULL,
	[IsTransferAsset] [bit] NULL,
	[ContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL
)
GO
