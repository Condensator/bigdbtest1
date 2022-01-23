CREATE TYPE [dbo].[ReceivableSKUTaxReversalDetailParameter] AS TABLE(
	[Revenue_Amount] [decimal](16, 2) NOT NULL,
	[Revenue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[AmountBilledToDate_Amount] [decimal](16, 2) NOT NULL
)
GO
