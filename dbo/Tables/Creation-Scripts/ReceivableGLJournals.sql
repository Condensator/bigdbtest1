SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableGLJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NOT NULL,
	[ReversalGLJournalOfId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceivable_ReceivableGLJournals] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableGLJournals] CHECK CONSTRAINT [EReceivable_ReceivableGLJournals]
GO
ALTER TABLE [dbo].[ReceivableGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceivableGLJournal_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[ReceivableGLJournals] CHECK CONSTRAINT [EReceivableGLJournal_GLJournal]
GO
ALTER TABLE [dbo].[ReceivableGLJournals]  WITH CHECK ADD  CONSTRAINT [EReceivableGLJournal_ReversalGLJournalOf] FOREIGN KEY([ReversalGLJournalOfId])
REFERENCES [dbo].[ReceivableGLJournals] ([Id])
GO
ALTER TABLE [dbo].[ReceivableGLJournals] CHECK CONSTRAINT [EReceivableGLJournal_ReversalGLJournalOf]
GO
