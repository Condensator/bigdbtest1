SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetMaintenances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveTillDate] [date] NULL,
	[IsCurrent] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[UpdatedById] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetMaintenances]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetMaintenances] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetMaintenances] CHECK CONSTRAINT [EAsset_AssetMaintenances]
GO
ALTER TABLE [dbo].[AssetMaintenances]  WITH CHECK ADD  CONSTRAINT [EAssetMaintenance_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[AssetMaintenances] CHECK CONSTRAINT [EAssetMaintenance_Location]
GO
