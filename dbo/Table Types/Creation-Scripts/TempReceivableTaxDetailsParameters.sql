CREATE TYPE [dbo].[TempReceivableTaxDetailsParameters] AS TABLE(
	[UpfrontTaxMode] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxBasisType] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[NonVertexExtract_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[AssetCost] [decimal](16, 2) NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[Amount] [decimal](16, 2) NOT NULL,
	[TaxDetail_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableId] [bigint] NOT NULL
)
GO
