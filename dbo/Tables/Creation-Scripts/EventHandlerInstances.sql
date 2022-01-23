SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventHandlerInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RetryCount] [int] NULL,
	[EventHandlerConfigId] [bigint] NOT NULL,
	[EventInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EventHandlerInstances]  WITH CHECK ADD  CONSTRAINT [EEventHandlerInstance_EventHandlerConfig] FOREIGN KEY([EventHandlerConfigId])
REFERENCES [dbo].[EventHandlerConfigs] ([Id])
GO
ALTER TABLE [dbo].[EventHandlerInstances] CHECK CONSTRAINT [EEventHandlerInstance_EventHandlerConfig]
GO
ALTER TABLE [dbo].[EventHandlerInstances]  WITH CHECK ADD  CONSTRAINT [EEventInstance_EventHandlerInstances] FOREIGN KEY([EventInstanceId])
REFERENCES [dbo].[EventInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EventHandlerInstances] CHECK CONSTRAINT [EEventInstance_EventHandlerInstances]
GO
