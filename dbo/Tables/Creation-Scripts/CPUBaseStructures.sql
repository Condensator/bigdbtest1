SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUBaseStructures](
	[Id] [bigint] NOT NULL,
	[IsAggregate] [bit] NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BaseUnit] [int] NULL,
	[NumberofPayments] [int] NULL,
	[FrequencyStartDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsRegularPaymentStream] [bit] NOT NULL,
	[DistributionBasis] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[AssetPaymentScheduleUpload_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[AssetPaymentScheduleUpload_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[AssetPaymentScheduleUpload_Content] [varbinary](82) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUBaseStructures]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_CPUBaseStructure] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUBaseStructures] CHECK CONSTRAINT [ECPUSchedule_CPUBaseStructure]
GO
