SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InstrumentTypeGLAccounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GLAccountNumber] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[UseRollupCostCenter] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[GLEntryItemId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts]  WITH CHECK ADD  CONSTRAINT [EInstrumentTypeGLAccount_GLEntryItem] FOREIGN KEY([GLEntryItemId])
REFERENCES [dbo].[GLEntryItems] ([Id])
GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts] CHECK CONSTRAINT [EInstrumentTypeGLAccount_GLEntryItem]
GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts]  WITH CHECK ADD  CONSTRAINT [EInstrumentTypeGLAccount_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts] CHECK CONSTRAINT [EInstrumentTypeGLAccount_GLTemplate]
GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts]  WITH CHECK ADD  CONSTRAINT [EInstrumentTypeGLAccount_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[InstrumentTypeGLAccounts] CHECK CONSTRAINT [EInstrumentTypeGLAccount_InstrumentType]
GO
