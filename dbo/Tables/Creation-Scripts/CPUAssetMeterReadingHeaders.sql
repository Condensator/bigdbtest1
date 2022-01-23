SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUAssetMeterReadingHeaders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPUAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUAssetMeterReadingHeaders]  WITH CHECK ADD  CONSTRAINT [ECPUAssetMeterReadingHeader_CPUAsset] FOREIGN KEY([CPUAssetId])
REFERENCES [dbo].[CPUAssets] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetMeterReadingHeaders] CHECK CONSTRAINT [ECPUAssetMeterReadingHeader_CPUAsset]
GO
