SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanInterestRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InterestRateDetailId] [bigint] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanInterestRates]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanInterestRates] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanInterestRates] CHECK CONSTRAINT [ELoanFinance_LoanInterestRates]
GO
ALTER TABLE [dbo].[LoanInterestRates]  WITH CHECK ADD  CONSTRAINT [ELoanInterestRate_InterestRateDetail] FOREIGN KEY([InterestRateDetailId])
REFERENCES [dbo].[InterestRateDetails] ([Id])
GO
ALTER TABLE [dbo].[LoanInterestRates] CHECK CONSTRAINT [ELoanInterestRate_InterestRateDetail]
GO
