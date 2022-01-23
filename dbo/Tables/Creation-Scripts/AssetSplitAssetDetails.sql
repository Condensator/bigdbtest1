SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSplitAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NewAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[NewAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NewQuantity] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewAssetId] [bigint] NULL,
	[AssetSplitAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssetFeatureId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSplitAssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSplitAsset_AssetSplitAssetDetails] FOREIGN KEY([AssetSplitAssetId])
REFERENCES [dbo].[AssetSplitAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSplitAssetDetails] CHECK CONSTRAINT [EAssetSplitAsset_AssetSplitAssetDetails]
GO
ALTER TABLE [dbo].[AssetSplitAssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSplitAssetDetail_AssetFeature] FOREIGN KEY([AssetFeatureId])
REFERENCES [dbo].[AssetFeatures] ([Id])
GO
ALTER TABLE [dbo].[AssetSplitAssetDetails] CHECK CONSTRAINT [EAssetSplitAssetDetail_AssetFeature]
GO
ALTER TABLE [dbo].[AssetSplitAssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSplitAssetDetail_NewAsset] FOREIGN KEY([NewAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSplitAssetDetails] CHECK CONSTRAINT [EAssetSplitAssetDetail_NewAsset]
GO
