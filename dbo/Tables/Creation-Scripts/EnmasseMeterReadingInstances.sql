SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnmasseMeterReadingInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CPINumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SerialNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MeterType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EndPeriodDate] [date] NULL,
	[ReadDate] [date] NULL,
	[BeginReading] [bigint] NULL,
	[EndReading] [bigint] NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[MeterResetType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsFaulted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPUAssetId] [bigint] NULL,
	[IsFirstReading] [bit] NOT NULL,
	[IsCorrection] [bit] NOT NULL,
	[BeginPeriodDate] [date] NULL,
	[InstanceId] [uniqueidentifier] NULL,
	[MatchedAssetId] [bigint] NULL,
	[CPUContractId] [bigint] NULL,
	[AssetBeginDate] [date] NULL,
	[AssetMeterTypeId] [bigint] NULL,
	[CPUScheduleId] [bigint] NULL,
	[PortFolioId] [bigint] NULL,
	[CPUAssetMeterReadingHeaderId] [bigint] NULL,
	[IsAggregate] [bit] NOT NULL,
	[MeterMaxReading] [bigint] NULL,
	[RowId] [bigint] NOT NULL,
	[OriginalBeginReading] [bigint] NULL,
	[OriginalSource] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFirstReadingCorrected] [bit] NOT NULL,
	[CPUOverageAssessmentId] [bigint] NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_AssetMeterType] FOREIGN KEY([AssetMeterTypeId])
REFERENCES [dbo].[AssetMeterTypes] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_AssetMeterType]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_CPUAsset] FOREIGN KEY([CPUAssetId])
REFERENCES [dbo].[CPUAssets] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_CPUAsset]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_CPUAssetMeterReadingHeader] FOREIGN KEY([CPUAssetMeterReadingHeaderId])
REFERENCES [dbo].[CPUAssetMeterReadingHeaders] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_CPUAssetMeterReadingHeader]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_CPUContract] FOREIGN KEY([CPUContractId])
REFERENCES [dbo].[CPUContracts] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_CPUContract]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_CPUOverageAssessment] FOREIGN KEY([CPUOverageAssessmentId])
REFERENCES [dbo].[CPUOverageAssessments] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_CPUOverageAssessment]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_CPUSchedule] FOREIGN KEY([CPUScheduleId])
REFERENCES [dbo].[CPUSchedules] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_CPUSchedule]
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances]  WITH CHECK ADD  CONSTRAINT [EEnmasseMeterReadingInstance_MatchedAsset] FOREIGN KEY([MatchedAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[EnmasseMeterReadingInstances] CHECK CONSTRAINT [EEnmasseMeterReadingInstance_MatchedAsset]
GO
