CREATE TYPE [dbo].[JobInstance] AS TABLE(
	[StartDate] [datetimeoffset](7) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvocationReason] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[BusinessDate] [date] NOT NULL,
	[JobId] [bigint] NOT NULL,
	[SourceJobInstanceId] [bigint] NULL,
	[JobServiceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
