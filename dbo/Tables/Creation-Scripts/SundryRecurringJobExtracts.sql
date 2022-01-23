SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SundryRecurringJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SundryRecurringId] [bigint] NOT NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
