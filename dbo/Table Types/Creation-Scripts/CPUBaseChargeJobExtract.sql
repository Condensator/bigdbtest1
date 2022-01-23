CREATE TYPE [dbo].[CPUBaseChargeJobExtract] AS TABLE(
	[CPUContractId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPUContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[CPUScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ComputedProcessThroughDate] [date] NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
