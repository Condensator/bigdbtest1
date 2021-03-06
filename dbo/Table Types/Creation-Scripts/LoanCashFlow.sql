CREATE TYPE [dbo].[LoanCashFlow] AS TABLE(
	[Date] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
