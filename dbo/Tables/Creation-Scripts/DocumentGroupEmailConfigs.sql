SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentGroupEmailConfigs](
	[Id] [bigint] NOT NULL,
	[FromEmailExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ToEmailConfigId] [bigint] NOT NULL,
	[CcEmailConfigId] [bigint] NULL,
	[BccEmailConfigId] [bigint] NULL,
	[EmailTemplateId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[DocumentGroupEmailConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentGroup_DocumentGroupEmailConfig] FOREIGN KEY([Id])
REFERENCES [dbo].[DocumentGroups] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs] CHECK CONSTRAINT [EDocumentGroup_DocumentGroupEmailConfig]
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupEmailConfig_BccEmailConfig] FOREIGN KEY([BccEmailConfigId])
REFERENCES [dbo].[DocumentEntityEmailConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs] CHECK CONSTRAINT [EDocumentGroupEmailConfig_BccEmailConfig]
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupEmailConfig_CcEmailConfig] FOREIGN KEY([CcEmailConfigId])
REFERENCES [dbo].[DocumentEntityEmailConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs] CHECK CONSTRAINT [EDocumentGroupEmailConfig_CcEmailConfig]
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupEmailConfig_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs] CHECK CONSTRAINT [EDocumentGroupEmailConfig_EmailTemplate]
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentGroupEmailConfig_ToEmailConfig] FOREIGN KEY([ToEmailConfigId])
REFERENCES [dbo].[DocumentEntityEmailConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentGroupEmailConfigs] CHECK CONSTRAINT [EDocumentGroupEmailConfig_ToEmailConfig]
GO
