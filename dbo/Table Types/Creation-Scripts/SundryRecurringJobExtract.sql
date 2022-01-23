CREATE TYPE [dbo].[SundryRecurringJobExtract] AS TABLE(
	[SundryRecurringId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FunderId] [bigint] NULL,
	[IsSyndicated] [bit] NOT NULL,
	[IsAdvance] [bit] NOT NULL,
	[ComputedProcessThroughDate] [date] NOT NULL,
	[LastExtensionARUpdateRunDate] [date] NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
