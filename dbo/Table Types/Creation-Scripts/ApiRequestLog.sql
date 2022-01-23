CREATE TYPE [dbo].[ApiRequestLog] AS TABLE(
	[CorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[HostName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicationName] [nvarchar](256) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[HttpRequestClientHostIP] [nvarchar](39) COLLATE Latin1_General_CI_AS NOT NULL,
	[Method] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[RawUrl] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[StatusCode] [int] NULL,
	[RequestContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ResponseContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ElapsedMilliseconds] [bigint] NULL,
	[LoginAuditId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
