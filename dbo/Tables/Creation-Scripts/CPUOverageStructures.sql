SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageStructures](
	[Id] [bigint] NOT NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[FrequencyStartDate] [date] NULL,
	[OverageTier] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[NoOfPeriodsToAverage] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageStructures]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_CPUOverageStructure] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageStructures] CHECK CONSTRAINT [ECPUSchedule_CPUOverageStructure]
GO
