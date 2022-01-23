CREATE TYPE [dbo].[ReceivableSKUTaxReversalDetailDatas] AS TABLE(
	[Amount] [decimal](16, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AmountBilledToDate] [decimal](16, 2) NULL,
	[Cost] [decimal](16, 2) NULL,
	[FairMarketValue] [decimal](16, 2) NULL,
	[IsExemptAtAssetSKU] [bit] NULL,
	[ReceivableSKUId] [bigint] NULL,
	[Revenue] [decimal](16, 2) NULL,
	[RevenueCurrency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetSKUId] [bigint] NULL,
	[ReceivableTaxDetailId] [bigint] NULL
)
GO
