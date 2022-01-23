SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanCashFlows](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [date] NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Residual_Amount] [decimal](16, 2) NOT NULL,
	[Residual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Equity_Amount] [decimal](16, 2) NOT NULL,
	[Equity_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Fees_Amount] [decimal](16, 2) NOT NULL,
	[Fees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreTaxCashFlow_Amount] [decimal](16, 2) NOT NULL,
	[PreTaxCashFlow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Taxpaid_Amount] [decimal](16, 2) NOT NULL,
	[Taxpaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostTaxCashFlow_Amount] [decimal](16, 2) NOT NULL,
	[PostTaxCashFlow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CumulativePostTaxCashFlow_Amount] [decimal](16, 2) NOT NULL,
	[CumulativePostTaxCashFlow_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PeriodicIncome_Amount] [decimal](16, 2) NOT NULL,
	[PeriodicIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PeriodicExpense_Amount] [decimal](16, 2) NOT NULL,
	[PeriodicExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FederalTaxPaid_Amount] [decimal](16, 2) NOT NULL,
	[FederalTaxPaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StateTaxPaid_Amount] [decimal](16, 2) NOT NULL,
	[StateTaxPaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SecurityDepositAmount_Amount] [decimal](16, 2) NOT NULL,
	[SecurityDepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LendingLoanTakedown_Amount] [decimal](16, 2) NOT NULL,
	[LendingLoanTakedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanCashFlows]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanCashFlows] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanCashFlows] CHECK CONSTRAINT [ELoanFinance_LoanCashFlows]
GO
