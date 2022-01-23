SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IncomingMessageInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CorrelationId] [uniqueidentifier] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MessageId] [uniqueidentifier] NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Content] [varbinary](max) NOT NULL,
	[MessageBrokerEndpointId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[IncomingMessageInstances]  WITH CHECK ADD  CONSTRAINT [EIncomingMessageInstance_MessageBrokerEndpoint] FOREIGN KEY([MessageBrokerEndpointId])
REFERENCES [dbo].[MessageBrokerEndpoints] ([Id])
GO
ALTER TABLE [dbo].[IncomingMessageInstances] CHECK CONSTRAINT [EIncomingMessageInstance_MessageBrokerEndpoint]
GO
