SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetRepossessionLocations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveFromDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveTillDate] [date] NULL,
	[IsCurrent] [bit] NULL,
	[IsActive] [bit] NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetRepossessionLocations]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetRepossessionLocations] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetRepossessionLocations] CHECK CONSTRAINT [EAsset_AssetRepossessionLocations]
GO
ALTER TABLE [dbo].[AssetRepossessionLocations]  WITH CHECK ADD  CONSTRAINT [EAssetRepossessionLocation_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssetRepossessionLocations] CHECK CONSTRAINT [EAssetRepossessionLocation_Location]
GO
