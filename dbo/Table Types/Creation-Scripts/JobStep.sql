CREATE TYPE [dbo].[JobStep] AS TABLE(
	[TaskParam] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExecutionOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OnHold] [bit] NOT NULL,
	[RunOnHoliday] [bit] NOT NULL,
	[AbortOnFailure] [bit] NOT NULL,
	[ReRun] [bit] NOT NULL,
	[LatestInstanceStatus] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[EmailAttachment] [bit] NOT NULL,
	[TaskId] [bigint] NOT NULL,
	[JobId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
