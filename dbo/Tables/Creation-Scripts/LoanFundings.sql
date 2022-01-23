SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanFundings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [int] NOT NULL,
	[UsePayDate] [bit] NOT NULL,
	[IsEligibleForInterimBilling] [bit] NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Type] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundingId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanFundings]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanFundings] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanFundings] CHECK CONSTRAINT [ELoanFinance_LoanFundings]
GO
ALTER TABLE [dbo].[LoanFundings]  WITH CHECK ADD  CONSTRAINT [ELoanFunding_Funding] FOREIGN KEY([FundingId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LoanFundings] CHECK CONSTRAINT [ELoanFunding_Funding]
GO
