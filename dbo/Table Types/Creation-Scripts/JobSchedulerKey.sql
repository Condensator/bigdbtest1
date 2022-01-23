CREATE TYPE [dbo].[JobSchedulerKey] AS TABLE(
	[JobInvocationReason] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UniqueId] [uniqueidentifier] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[JobId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
