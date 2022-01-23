CREATE TYPE [dbo].[ReceivableTaxDetailsParameters] AS TABLE(
	[TaxBasisType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[Revenue_Amount] [decimal](16, 2) NOT NULL,
	[Revenue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NOT NULL
)
GO
