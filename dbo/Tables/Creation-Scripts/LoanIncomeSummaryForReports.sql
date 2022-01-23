SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanIncomeSummaryForReports](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[PaymentType] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IncomeDate] [date] NOT NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestRate] [decimal](10, 6) NULL,
	[InterestAccrued_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestPayment_Amount] [decimal](16, 2) NOT NULL,
	[InterestPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalPayment_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalAdded_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalAdded_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndBalance_Amount] [decimal](16, 2) NOT NULL,
	[EndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Suspended] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BlendedItemName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BlendedIncome_Amount] [decimal](16, 2) NOT NULL,
	[BlendedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BlendedIncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[BlendedIncomeBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsBlendedIncomeRecord] [bit] NOT NULL,
	[IsYieldExtreme] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActualBlendedIncomeRecord] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanIncomeSummaryForReports]  WITH CHECK ADD  CONSTRAINT [ELoanIncomeSummaryForReport_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LoanIncomeSummaryForReports] CHECK CONSTRAINT [ELoanIncomeSummaryForReport_Contract]
GO
