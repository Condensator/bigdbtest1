CREATE TYPE [dbo].[TraceEventLog] AS TABLE(
	[EventType] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EventDate] [datetimeoffset](7) NOT NULL,
	[UserId] [bigint] NOT NULL,
	[ClientIPAddress] [nvarchar](39) COLLATE Latin1_General_CI_AS NULL,
	[Form] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Transaction] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
