SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReAccrualRuleReceivableTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NULL,
	[ReAccrualRuleTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReAccrualRuleReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EReAccrualRuleReceivableType_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReAccrualRuleReceivableTypes] CHECK CONSTRAINT [EReAccrualRuleReceivableType_ReceivableType]
GO
ALTER TABLE [dbo].[ReAccrualRuleReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EReAccrualRuleTemplate_ReAccrualRuleReceivableTypes] FOREIGN KEY([ReAccrualRuleTemplateId])
REFERENCES [dbo].[ReAccrualRuleTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReAccrualRuleReceivableTypes] CHECK CONSTRAINT [EReAccrualRuleTemplate_ReAccrualRuleReceivableTypes]
GO
