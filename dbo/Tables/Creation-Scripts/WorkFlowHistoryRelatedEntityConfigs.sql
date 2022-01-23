SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkFlowHistoryRelatedEntityConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelatedEntityConfigId] [bigint] NOT NULL,
	[WorkFlowHistoryEntityConfigId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkFlowHistoryEntityConfig_WorkFlowHistoryRelatedEntityConfigs] FOREIGN KEY([WorkFlowHistoryEntityConfigId])
REFERENCES [dbo].[WorkFlowHistoryEntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityConfigs] CHECK CONSTRAINT [EWorkFlowHistoryEntityConfig_WorkFlowHistoryRelatedEntityConfigs]
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkFlowHistoryRelatedEntityConfig_RelatedEntityConfig] FOREIGN KEY([RelatedEntityConfigId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkFlowHistoryRelatedEntityConfigs] CHECK CONSTRAINT [EWorkFlowHistoryRelatedEntityConfig_RelatedEntityConfig]
GO
