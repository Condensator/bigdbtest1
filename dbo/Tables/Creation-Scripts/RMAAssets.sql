SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RMAAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RMAAssetStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RMAProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[UpdatedById] [bigint] NULL,
	[WarehouseLocationId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RMAAssets]  WITH CHECK ADD  CONSTRAINT [ERMAAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[RMAAssets] CHECK CONSTRAINT [ERMAAsset_Asset]
GO
ALTER TABLE [dbo].[RMAAssets]  WITH CHECK ADD  CONSTRAINT [ERMAAsset_WarehouseLocation] FOREIGN KEY([WarehouseLocationId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[RMAAssets] CHECK CONSTRAINT [ERMAAsset_WarehouseLocation]
GO
ALTER TABLE [dbo].[RMAAssets]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_RMAAssets] FOREIGN KEY([RMAProfileId])
REFERENCES [dbo].[RMAProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RMAAssets] CHECK CONSTRAINT [ERMAProfile_RMAAssets]
GO
