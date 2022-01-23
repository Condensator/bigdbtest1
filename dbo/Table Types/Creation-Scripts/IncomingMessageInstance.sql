CREATE TYPE [dbo].[IncomingMessageInstance] AS TABLE(
	[CorrelationId] [uniqueidentifier] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MessageId] [uniqueidentifier] NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Content] [varbinary](max) NOT NULL,
	[MessageBrokerEndpointId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
