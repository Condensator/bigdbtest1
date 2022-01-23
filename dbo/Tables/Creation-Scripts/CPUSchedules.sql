SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CommencementDate] [date] NOT NULL,
	[EstimationMethod] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[MeterTypeId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsBasePaymentScheduleGenerationRequired] [bit] NOT NULL,
	[BaseJobRanForCompletion] [bit] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[PayoffDate] [date] NULL,
	[IsOverageTierScheduleGenerationRequired] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_CPUSchedules] FOREIGN KEY([CPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUSchedules] CHECK CONSTRAINT [ECPUFinance_CPUSchedules]
GO
ALTER TABLE [dbo].[CPUSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_MeterType] FOREIGN KEY([MeterTypeId])
REFERENCES [dbo].[AssetMeterTypes] ([Id])
GO
ALTER TABLE [dbo].[CPUSchedules] CHECK CONSTRAINT [ECPUSchedule_MeterType]
GO
