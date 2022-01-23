SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteLoans](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreQuoteContractId] [bigint] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LoanPaydownId] [bigint] NULL,
	[PrincipalBalance_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestBalance_Amount] [decimal](16, 2) NOT NULL,
	[InterestBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmortProcessThroughDate] [date] NULL,
	[AsOfDate] [date] NULL,
	[HasPrePaymentPenalty] [bit] NOT NULL,
	[LoanAmount_Amount] [decimal](16, 2) NOT NULL,
	[LoanAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ManagementYield] [decimal](28, 18) NOT NULL,
	[OutstandingLoanRental_Amount] [decimal](16, 2) NOT NULL,
	[OutstandingLoanRental_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteLoans]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteLoans] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteLoans] CHECK CONSTRAINT [EPreQuote_PreQuoteLoans]
GO
ALTER TABLE [dbo].[PreQuoteLoans]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLoan_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLoans] CHECK CONSTRAINT [EPreQuoteLoan_LoanFinance]
GO
ALTER TABLE [dbo].[PreQuoteLoans]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLoan_LoanPaydown] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLoans] CHECK CONSTRAINT [EPreQuoteLoan_LoanPaydown]
GO
ALTER TABLE [dbo].[PreQuoteLoans]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLoan_PreQuoteContract] FOREIGN KEY([PreQuoteContractId])
REFERENCES [dbo].[PreQuoteContracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLoans] CHECK CONSTRAINT [EPreQuoteLoan_PreQuoteContract]
GO
