SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLManualJournalEntries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[ReversalPostDate] [date] NULL,
	[ManualGLTransactionType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[AssetSaleId] [bigint] NULL,
	[ReceivableForTransferId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[ReferenceGLManualId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsGLExportRequired] [bit] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_Asset]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_AssetSale] FOREIGN KEY([AssetSaleId])
REFERENCES [dbo].[AssetSales] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_AssetSale]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_Contract]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_CostCenter]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_Currency]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_GLJournal]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_InstrumentType]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_LegalEntity]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_LineofBusiness]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_ReceivableForTransfer] FOREIGN KEY([ReceivableForTransferId])
REFERENCES [dbo].[ReceivableForTransfers] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_ReceivableForTransfer]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_ReferenceGLManual] FOREIGN KEY([ReferenceGLManualId])
REFERENCES [dbo].[GLManualJournalEntries] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_ReferenceGLManual]
GO
ALTER TABLE [dbo].[GLManualJournalEntries]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntries] CHECK CONSTRAINT [EGLManualJournalEntry_ReversalGLJournal]
GO
