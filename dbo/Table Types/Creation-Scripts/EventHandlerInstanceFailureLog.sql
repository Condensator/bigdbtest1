CREATE TYPE [dbo].[EventHandlerInstanceFailureLog] AS TABLE(
	[Message] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Fault] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RetryCount] [int] NULL,
	[EventHandlerInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
