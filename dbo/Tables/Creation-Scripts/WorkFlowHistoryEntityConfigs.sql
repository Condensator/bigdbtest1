SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkFlowHistoryEntityConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[WorkFlowHistoryEntityConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkFlowHistoryEntityConfig_EntityConfig] FOREIGN KEY([EntityConfigId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkFlowHistoryEntityConfigs] CHECK CONSTRAINT [EWorkFlowHistoryEntityConfig_EntityConfig]
GO
