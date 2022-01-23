SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableGLJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[IsReversal] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NOT NULL,
	[PayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableGLJournals]  WITH CHECK ADD  CONSTRAINT [EPayable_PayableGLJournals] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableGLJournals] CHECK CONSTRAINT [EPayable_PayableGLJournals]
GO
ALTER TABLE [dbo].[PayableGLJournals]  WITH CHECK ADD  CONSTRAINT [EPayableGLJournal_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayableGLJournals] CHECK CONSTRAINT [EPayableGLJournal_GLJournal]
GO
