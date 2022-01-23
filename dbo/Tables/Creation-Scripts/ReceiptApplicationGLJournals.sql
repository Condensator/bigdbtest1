SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationGLJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsReversal] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NOT NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptApplicationGLJournals] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals] CHECK CONSTRAINT [EReceiptApplication_ReceiptApplicationGLJournals]
GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationGLJournal_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals] CHECK CONSTRAINT [EReceiptApplicationGLJournal_GLJournal]
GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationGLJournal_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationGLJournals] CHECK CONSTRAINT [EReceiptApplicationGLJournal_LegalEntity]
GO
