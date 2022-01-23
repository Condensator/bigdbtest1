SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentStatusRequirementConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[ActionId] [bigint] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusRequirementConfig_Action] FOREIGN KEY([ActionId])
REFERENCES [dbo].[WorkItemActionConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs] CHECK CONSTRAINT [EDocumentStatusRequirementConfig_Action]
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusRequirementConfig_DocumentType] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs] CHECK CONSTRAINT [EDocumentStatusRequirementConfig_DocumentType]
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusRequirementConfig_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusForTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs] CHECK CONSTRAINT [EDocumentStatusRequirementConfig_Status]
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs]  WITH CHECK ADD  CONSTRAINT [ETransactionConfig_DocumentStatusRequirementConfigs] FOREIGN KEY([TransactionConfigId])
REFERENCES [dbo].[TransactionConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentStatusRequirementConfigs] CHECK CONSTRAINT [ETransactionConfig_DocumentStatusRequirementConfigs]
GO
