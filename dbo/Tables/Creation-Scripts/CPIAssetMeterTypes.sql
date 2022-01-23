SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIAssetMeterTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OldReading] [int] NOT NULL,
	[NewReading] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetMeterTypeId] [bigint] NOT NULL,
	[CPIAssetMeterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIAssetMeterTypes]  WITH CHECK ADD  CONSTRAINT [ECPIAssetMeter_CPIAssetMeterTypes] FOREIGN KEY([CPIAssetMeterId])
REFERENCES [dbo].[CPIAssetMeters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIAssetMeterTypes] CHECK CONSTRAINT [ECPIAssetMeter_CPIAssetMeterTypes]
GO
ALTER TABLE [dbo].[CPIAssetMeterTypes]  WITH CHECK ADD  CONSTRAINT [ECPIAssetMeterType_AssetMeterType] FOREIGN KEY([AssetMeterTypeId])
REFERENCES [dbo].[AssetMeterTypes] ([Id])
GO
ALTER TABLE [dbo].[CPIAssetMeterTypes] CHECK CONSTRAINT [ECPIAssetMeterType_AssetMeterType]
GO
