SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUBaseChargeJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[CPUContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[CPUScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ComputedProcessThroughDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
