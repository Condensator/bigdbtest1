SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoffTemplateLegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OperatingLeasePayoffGLTemplateId] [bigint] NULL,
	[CapitalLeasePayoffGLTemplateId] [bigint] NULL,
	[InventoryBookDepGLTemplateId] [bigint] NULL,
	[PayoffReceivableCodeId] [bigint] NULL,
	[BuyoutReceivableCodeId] [bigint] NULL,
	[SundryReceivableCodeId] [bigint] NULL,
	[TaxDepDisposalGLTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplate_AutoPayoffTemplateLegalEntities] FOREIGN KEY([AutoPayoffTemplateId])
REFERENCES [dbo].[AutoPayoffTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplate_AutoPayoffTemplateLegalEntities]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_BuyoutReceivableCode] FOREIGN KEY([BuyoutReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_BuyoutReceivableCode]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_CapitalLeasePayoffGLTemplate] FOREIGN KEY([CapitalLeasePayoffGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_CapitalLeasePayoffGLTemplate]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_InventoryBookDepGLTemplate] FOREIGN KEY([InventoryBookDepGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_InventoryBookDepGLTemplate]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_LegalEntity]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_OperatingLeasePayoffGLTemplate] FOREIGN KEY([OperatingLeasePayoffGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_OperatingLeasePayoffGLTemplate]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_PayoffReceivableCode] FOREIGN KEY([PayoffReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_PayoffReceivableCode]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_SundryReceivableCode] FOREIGN KEY([SundryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_SundryReceivableCode]
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffTemplateLegalEntity_TaxDepDisposalGLTemplate] FOREIGN KEY([TaxDepDisposalGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffTemplateLegalEntities] CHECK CONSTRAINT [EAutoPayoffTemplateLegalEntity_TaxDepDisposalGLTemplate]
GO
