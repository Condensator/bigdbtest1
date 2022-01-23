SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractBillings](
	[Id] [bigint] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceCommentBeginDate] [date] NULL,
	[InvoiceCommentEndDate] [date] NULL,
	[InvoiceLeaddays] [int] NOT NULL,
	[IsPreACHNotification] [bit] NOT NULL,
	[PreACHNotificationEmail] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[NotaryDate] [date] NULL,
	[ActaNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[PreACHNotificationEmailTemplateId] [bigint] NULL,
	[ReceiptLegalEntityId] [bigint] NULL,
	[IsPostACHNotification] [bit] NOT NULL,
	[PostACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[PostACHNotificationEmailTemplateId] [bigint] NULL,
	[IsReturnACHNotification] [bit] NOT NULL,
	[ReturnACHNotificationEmailTo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ReturnACHNotificationEmailTemplateId] [bigint] NULL,
	[InvoiceTransitDays] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractBillings]  WITH CHECK ADD  CONSTRAINT [EContract_ContractBilling] FOREIGN KEY([Id])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractBillings] CHECK CONSTRAINT [EContract_ContractBilling]
GO
ALTER TABLE [dbo].[ContractBillings]  WITH CHECK ADD  CONSTRAINT [EContractBilling_PostACHNotificationEmailTemplate] FOREIGN KEY([PostACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[ContractBillings] CHECK CONSTRAINT [EContractBilling_PostACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[ContractBillings]  WITH CHECK ADD  CONSTRAINT [EContractBilling_PreACHNotificationEmailTemplate] FOREIGN KEY([PreACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[ContractBillings] CHECK CONSTRAINT [EContractBilling_PreACHNotificationEmailTemplate]
GO
ALTER TABLE [dbo].[ContractBillings]  WITH CHECK ADD  CONSTRAINT [EContractBilling_ReceiptLegalEntity] FOREIGN KEY([ReceiptLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ContractBillings] CHECK CONSTRAINT [EContractBilling_ReceiptLegalEntity]
GO
ALTER TABLE [dbo].[ContractBillings]  WITH CHECK ADD  CONSTRAINT [EContractBilling_ReturnACHNotificationEmailTemplate] FOREIGN KEY([ReturnACHNotificationEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[ContractBillings] CHECK CONSTRAINT [EContractBilling_ReturnACHNotificationEmailTemplate]
GO
