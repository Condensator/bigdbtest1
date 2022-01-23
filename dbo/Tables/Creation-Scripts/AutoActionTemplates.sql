SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoActionTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntitySelectionSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreateWorkItem] [bit] NOT NULL,
	[CreateNotification] [bit] NOT NULL,
	[CreateComment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NULL,
	[TransactionConfigId] [bigint] NULL,
	[NotificationConfigId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpdateStoredProc] [nvarchar](128) COLLATE Latin1_General_CI_AS NULL,
	[MasterStoredProc] [nvarchar](128) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoActionTemplates]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplate_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[AutoActionEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[AutoActionTemplates] CHECK CONSTRAINT [EAutoActionTemplate_EntityType]
GO
ALTER TABLE [dbo].[AutoActionTemplates]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplate_NotificationConfig] FOREIGN KEY([NotificationConfigId])
REFERENCES [dbo].[NotificationConfigs] ([Id])
GO
ALTER TABLE [dbo].[AutoActionTemplates] CHECK CONSTRAINT [EAutoActionTemplate_NotificationConfig]
GO
ALTER TABLE [dbo].[AutoActionTemplates]  WITH CHECK ADD  CONSTRAINT [EAutoActionTemplate_TransactionConfig] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
GO
ALTER TABLE [dbo].[AutoActionTemplates] CHECK CONSTRAINT [EAutoActionTemplate_TransactionConfig]
GO
