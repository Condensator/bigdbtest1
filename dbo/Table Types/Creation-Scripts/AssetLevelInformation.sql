CREATE TYPE [dbo].[AssetLevelInformation] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[AssetRentOrCustomerCost] [decimal](16, 2) NOT NULL,
	[BillToId] [bigint] NULL,
	[RowNumber] [bigint] NULL,
	[MaturityPayment] [decimal](16, 2) NOT NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLeaseAsset] [bit] NULL,
	[HasSku] [bit] NULL,
	[AssetInLeaseDate] [date] NULL,
	[TerminationDate] [date] NULL,
	[PreCapitalizationRent] [decimal](16, 2) NOT NULL
)
GO
