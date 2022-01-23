SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanCapitalizedInterests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Source] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceOtherCostId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [ELoanCapitalizedInterest_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[LoanCapitalizedInterests] CHECK CONSTRAINT [ELoanCapitalizedInterest_GLJournal]
GO
ALTER TABLE [dbo].[LoanCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [ELoanCapitalizedInterest_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LoanCapitalizedInterests] CHECK CONSTRAINT [ELoanCapitalizedInterest_PayableInvoiceOtherCost]
GO
ALTER TABLE [dbo].[LoanCapitalizedInterests]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanCapitalizedInterests] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanCapitalizedInterests] CHECK CONSTRAINT [ELoanFinance_LoanCapitalizedInterests]
GO
