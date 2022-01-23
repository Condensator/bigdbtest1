SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIAssetMeters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NewReadingDate] [date] NULL,
	[OldReadingDate] [date] NULL,
	[IsOldReadingCalculated] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[CPIMeterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIAssetMeters]  WITH CHECK ADD  CONSTRAINT [ECPIAssetMeter_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPIAssetMeters] CHECK CONSTRAINT [ECPIAssetMeter_Asset]
GO
ALTER TABLE [dbo].[CPIAssetMeters]  WITH CHECK ADD  CONSTRAINT [ECPIMeter_CPIAssetMeters] FOREIGN KEY([CPIMeterId])
REFERENCES [dbo].[CPIMeters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIAssetMeters] CHECK CONSTRAINT [ECPIMeter_CPIAssetMeters]
GO
