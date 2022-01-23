SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffAssetSKUs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SKUValuation_Amount] [decimal](16, 2) NOT NULL,
	[SKUValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OLV_Amount] [decimal](16, 2) NOT NULL,
	[OLV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PlaceholderRent_Amount] [decimal](16, 2) NOT NULL,
	[PlaceholderRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBVAsOfEffectiveDate_Amount] [decimal](16, 2) NOT NULL,
	[NBVAsOfEffectiveDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseAssetSKUId] [bigint] NOT NULL,
	[PayoffAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffAssetSKUs]  WITH NOCHECK ADD  CONSTRAINT [EPayoffAsset_PayoffAssetSKUs] FOREIGN KEY([PayoffAssetId])
REFERENCES [dbo].[PayoffAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffAssetSKUs] NOCHECK CONSTRAINT [EPayoffAsset_PayoffAssetSKUs]
GO
ALTER TABLE [dbo].[PayoffAssetSKUs]  WITH NOCHECK ADD  CONSTRAINT [EPayoffAssetSKU_LeaseAssetSKU] FOREIGN KEY([LeaseAssetSKUId])
REFERENCES [dbo].[LeaseAssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[PayoffAssetSKUs] NOCHECK CONSTRAINT [EPayoffAssetSKU_LeaseAssetSKU]
GO
