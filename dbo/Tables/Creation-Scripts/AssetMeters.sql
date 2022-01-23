SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetMeters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginReading] [bigint] NOT NULL,
	[MaximumReading] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetMeterTypeId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetMeters]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetMeters] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetMeters] CHECK CONSTRAINT [EAsset_AssetMeters]
GO
ALTER TABLE [dbo].[AssetMeters]  WITH CHECK ADD  CONSTRAINT [EAssetMeter_AssetMeterType] FOREIGN KEY([AssetMeterTypeId])
REFERENCES [dbo].[AssetMeterTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetMeters] CHECK CONSTRAINT [EAssetMeter_AssetMeterType]
GO
