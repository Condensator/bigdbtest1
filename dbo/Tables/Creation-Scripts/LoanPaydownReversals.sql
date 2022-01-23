SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownReversals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[GlJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownReversals]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownReversal_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownReversals] CHECK CONSTRAINT [ELoanPaydownReversal_Contract]
GO
ALTER TABLE [dbo].[LoanPaydownReversals]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownReversal_GlJournal] FOREIGN KEY([GlJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownReversals] CHECK CONSTRAINT [ELoanPaydownReversal_GlJournal]
GO
ALTER TABLE [dbo].[LoanPaydownReversals]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownReversal_LoanPaydown] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownReversals] CHECK CONSTRAINT [ELoanPaydownReversal_LoanPaydown]
GO
