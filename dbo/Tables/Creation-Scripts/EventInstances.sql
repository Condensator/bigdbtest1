SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NULL,
	[EntitySummary] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CorrelationId] [uniqueidentifier] NOT NULL,
	[EventArg] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsExternalCall] [bit] NOT NULL,
	[IsMigrationCall] [bit] NOT NULL,
	[IsWebServiceCall] [bit] NOT NULL,
	[EventConfigId] [bigint] NOT NULL,
	[SubmittedUserId] [bigint] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[JobServiceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EventInstances]  WITH CHECK ADD  CONSTRAINT [EEventInstance_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[EventInstances] CHECK CONSTRAINT [EEventInstance_BusinessUnit]
GO
ALTER TABLE [dbo].[EventInstances]  WITH CHECK ADD  CONSTRAINT [EEventInstance_EventConfig] FOREIGN KEY([EventConfigId])
REFERENCES [dbo].[EventConfigs] ([Id])
GO
ALTER TABLE [dbo].[EventInstances] CHECK CONSTRAINT [EEventInstance_EventConfig]
GO
ALTER TABLE [dbo].[EventInstances]  WITH CHECK ADD  CONSTRAINT [EEventInstance_JobService] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
GO
ALTER TABLE [dbo].[EventInstances] CHECK CONSTRAINT [EEventInstance_JobService]
GO
ALTER TABLE [dbo].[EventInstances]  WITH CHECK ADD  CONSTRAINT [EEventInstance_SubmittedUser] FOREIGN KEY([SubmittedUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EventInstances] CHECK CONSTRAINT [EEventInstance_SubmittedUser]
GO
