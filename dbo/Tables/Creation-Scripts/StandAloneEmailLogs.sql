SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StandAloneEmailLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SourceEntityId] [bigint] NOT NULL,
	[SourceEntityConfigId] [bigint] NOT NULL,
	[EntityConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[StandAloneEmailLogs]  WITH CHECK ADD  CONSTRAINT [EStandAloneEmailLog_EntityConfig] FOREIGN KEY([EntityConfigId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[StandAloneEmailLogs] CHECK CONSTRAINT [EStandAloneEmailLog_EntityConfig]
GO
ALTER TABLE [dbo].[StandAloneEmailLogs]  WITH CHECK ADD  CONSTRAINT [EStandAloneEmailLog_SourceEntityConfig] FOREIGN KEY([SourceEntityConfigId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[StandAloneEmailLogs] CHECK CONSTRAINT [EStandAloneEmailLog_SourceEntityConfig]
GO
