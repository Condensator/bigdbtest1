SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivitySubSystemConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsEnabledInUI] [bit] NOT NULL,
	[EnableRuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[ActivityEntityConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivitySubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EActivityEntityConfig_ActivitySubSystemConfigs] FOREIGN KEY([ActivityEntityConfigId])
REFERENCES [dbo].[ActivityEntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivitySubSystemConfigs] CHECK CONSTRAINT [EActivityEntityConfig_ActivitySubSystemConfigs]
GO
ALTER TABLE [dbo].[ActivitySubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EActivitySubSystemConfig_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivitySubSystemConfigs] CHECK CONSTRAINT [EActivitySubSystemConfig_SubSystem]
GO
