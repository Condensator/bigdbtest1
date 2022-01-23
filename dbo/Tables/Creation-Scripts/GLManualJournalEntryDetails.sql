SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLManualJournalEntryDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsDebit] [bit] NOT NULL,
	[GLAccountNumber] [nvarchar](129) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLAccountId] [bigint] NOT NULL,
	[GLManualJournalEntryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[GLJournalDetailId] [bigint] NULL,
	[ReversalGLJournalDetailId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntry_GLManualJournalEntryDetails] FOREIGN KEY([GLManualJournalEntryId])
REFERENCES [dbo].[GLManualJournalEntries] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails] CHECK CONSTRAINT [EGLManualJournalEntry_GLManualJournalEntryDetails]
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntryDetail_GLAccount] FOREIGN KEY([GLAccountId])
REFERENCES [dbo].[GLAccounts] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails] CHECK CONSTRAINT [EGLManualJournalEntryDetail_GLAccount]
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntryDetail_GLJournalDetail] FOREIGN KEY([GLJournalDetailId])
REFERENCES [dbo].[GLJournalDetails] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails] CHECK CONSTRAINT [EGLManualJournalEntryDetail_GLJournalDetail]
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails]  WITH CHECK ADD  CONSTRAINT [EGLManualJournalEntryDetail_ReversalGLJournalDetail] FOREIGN KEY([ReversalGLJournalDetailId])
REFERENCES [dbo].[GLJournalDetails] ([Id])
GO
ALTER TABLE [dbo].[GLManualJournalEntryDetails] CHECK CONSTRAINT [EGLManualJournalEntryDetail_ReversalGLJournalDetail]
GO
