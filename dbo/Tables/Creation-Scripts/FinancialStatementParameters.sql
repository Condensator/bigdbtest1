SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FinancialStatementParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReportingPeriod] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date] [date] NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalAssets] [decimal](16, 2) NULL,
	[TotalLiabilities] [decimal](16, 2) NULL,
	[LTLiabilities] [decimal](16, 2) NULL,
	[Equity] [decimal](16, 2) NULL,
	[Revenue] [decimal](16, 2) NULL,
	[NetIncome] [decimal](16, 2) NULL,
	[EBIT] [decimal](16, 2) NULL,
	[STReceivables] [decimal](16, 2) NULL,
	[STLiabilities] [decimal](16, 2) NULL,
	[BankLoans] [decimal](16, 2) NULL,
	[PPE] [decimal](16, 2) NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FinancialStatementParameters]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionForCreditApplication_FinancialStatementParameters] FOREIGN KEY([CreditDecisionForCreditApplicationId])
REFERENCES [dbo].[CreditDecisionForCreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FinancialStatementParameters] CHECK CONSTRAINT [ECreditDecisionForCreditApplication_FinancialStatementParameters]
GO
