CREATE TYPE [dbo].[WebApplicationLog] AS TABLE(
	[CorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[HostName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicationName] [nvarchar](256) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Level] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RawUrl] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Message] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Exception] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
