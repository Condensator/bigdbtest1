CREATE TYPE [dbo].[EventHandlerInstance] AS TABLE(
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RetryCount] [int] NULL,
	[EventHandlerConfigId] [bigint] NOT NULL,
	[EventInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
