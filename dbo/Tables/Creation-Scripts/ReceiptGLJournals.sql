SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptGLJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[IsReversal] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceiptGLJournals] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptGLJournals] CHECK CONSTRAINT [EReceipt_ReceiptGLJournals]
GO
ALTER TABLE [dbo].[ReceiptGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceiptGLJournal_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[ReceiptGLJournals] CHECK CONSTRAINT [EReceiptGLJournal_GLJournal]
GO
ALTER TABLE [dbo].[ReceiptGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceiptGLJournal_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ReceiptGLJournals] CHECK CONSTRAINT [EReceiptGLJournal_LegalEntity]
GO
