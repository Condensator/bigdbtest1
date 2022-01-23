SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortizationGLHeaders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepAmortizationGLHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationGLHeader_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLHeaders] CHECK CONSTRAINT [ETaxDepAmortizationGLHeader_GLJournal]
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationGLHeader_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationGLHeaders] CHECK CONSTRAINT [ETaxDepAmortizationGLHeader_ReversalGLJournal]
GO
