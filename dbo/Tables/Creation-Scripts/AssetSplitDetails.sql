SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSplitDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SplitInto] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OriginalAssetId] [bigint] NOT NULL,
	[AssetSplitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TotalQuantity] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSplitDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSplit_AssetSplitDetails] FOREIGN KEY([AssetSplitId])
REFERENCES [dbo].[AssetSplits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSplitDetails] CHECK CONSTRAINT [EAssetSplit_AssetSplitDetails]
GO
ALTER TABLE [dbo].[AssetSplitDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSplitDetail_OriginalAsset] FOREIGN KEY([OriginalAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSplitDetails] CHECK CONSTRAINT [EAssetSplitDetail_OriginalAsset]
GO
