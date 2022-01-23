SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUAssetMeterReadings](
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BeginPeriodDate] [date] NOT NULL,
	[EndPeriodDate] [date] NOT NULL,
	[ReadDate] [date] NOT NULL,
	[BeginReading] [bigint] NOT NULL,
	[EndReading] [bigint] NOT NULL,
	[Reading] [bigint] NOT NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[IsCorrection] [bit] NOT NULL,
	[IsMeterReset] [bit] NOT NULL,
	[MeterResetType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[LinkedCPUAssetMeterReadingId] [bigint] NULL,
	[CPUAssetId] [bigint] NULL,
	[CPUAssetMeterReadingHeaderId] [bigint] NOT NULL,
	[CPUOverageAssessmentId] [bigint] NULL,
	[AssessmentEffectiveDate] [date] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUAssetMeterReadings]  WITH CHECK ADD  CONSTRAINT [ECPUAssetMeterReading_CPUAsset] FOREIGN KEY([CPUAssetId])
REFERENCES [dbo].[CPUAssets] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings] CHECK CONSTRAINT [ECPUAssetMeterReading_CPUAsset]
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings]  WITH CHECK ADD  CONSTRAINT [ECPUAssetMeterReading_CPUOverageAssessment] FOREIGN KEY([CPUOverageAssessmentId])
REFERENCES [dbo].[CPUOverageAssessments] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings] CHECK CONSTRAINT [ECPUAssetMeterReading_CPUOverageAssessment]
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings]  WITH CHECK ADD  CONSTRAINT [ECPUAssetMeterReading_LinkedCPUAssetMeterReading] FOREIGN KEY([LinkedCPUAssetMeterReadingId])
REFERENCES [dbo].[CPUAssetMeterReadings] ([Id])
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings] CHECK CONSTRAINT [ECPUAssetMeterReading_LinkedCPUAssetMeterReading]
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings]  WITH CHECK ADD  CONSTRAINT [ECPUAssetMeterReadingHeader_CPUAssetMeterReadings] FOREIGN KEY([CPUAssetMeterReadingHeaderId])
REFERENCES [dbo].[CPUAssetMeterReadingHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUAssetMeterReadings] CHECK CONSTRAINT [ECPUAssetMeterReadingHeader_CPUAssetMeterReadings]
GO
