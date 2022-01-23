CREATE TYPE [dbo].[MessageBrokerEndpoint] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Direction] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[QueueType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[ConnectionConfig] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ComponentName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
