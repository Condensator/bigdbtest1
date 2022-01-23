SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlendedItemAssetLevelCapitalizations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlendedItemAssetLevelCapitalizations]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_BlendedItemAssetLevelCapitalizations] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BlendedItemAssetLevelCapitalizations] CHECK CONSTRAINT [EBlendedItem_BlendedItemAssetLevelCapitalizations]
GO
ALTER TABLE [dbo].[BlendedItemAssetLevelCapitalizations]  WITH CHECK ADD  CONSTRAINT [EBlendedItemAssetLevelCapitalization_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemAssetLevelCapitalizations] CHECK CONSTRAINT [EBlendedItemAssetLevelCapitalization_LeaseAsset]
GO
