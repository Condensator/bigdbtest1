SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLJournalDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityType] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsDebit] [bit] NOT NULL,
	[GLAccountNumber] [nvarchar](129) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLAccountId] [bigint] NOT NULL,
	[GLTemplateDetailId] [bigint] NULL,
	[MatchingGLTemplateDetailId] [bigint] NULL,
	[ExportJobId] [bigint] NULL,
	[GLJournalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[InstrumentTypeGLAccountId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournal_GLJournalDetails] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournal_GLJournalDetails]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_ExportJob] FOREIGN KEY([ExportJobId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_ExportJob]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_GLAccount] FOREIGN KEY([GLAccountId])
REFERENCES [dbo].[GLAccounts] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_GLAccount]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_GLTemplateDetail] FOREIGN KEY([GLTemplateDetailId])
REFERENCES [dbo].[GLTemplateDetails] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_GLTemplateDetail]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_InstrumentTypeGLAccount] FOREIGN KEY([InstrumentTypeGLAccountId])
REFERENCES [dbo].[InstrumentTypeGLAccounts] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_InstrumentTypeGLAccount]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[GLJournalDetails]  WITH CHECK ADD  CONSTRAINT [EGLJournalDetail_MatchingGLTemplateDetail] FOREIGN KEY([MatchingGLTemplateDetailId])
REFERENCES [dbo].[GLTemplateDetails] ([Id])
GO
ALTER TABLE [dbo].[GLJournalDetails] CHECK CONSTRAINT [EGLJournalDetail_MatchingGLTemplateDetail]
GO
