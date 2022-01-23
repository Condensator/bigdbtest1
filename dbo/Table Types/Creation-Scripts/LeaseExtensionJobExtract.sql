CREATE TYPE [dbo].[LeaseExtensionJobExtract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[ComputedProcessThroughDate] [date] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
