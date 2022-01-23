SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DNAParametersForCreditDecisions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NetDisposableIncome_Amount] [decimal](16, 2) NULL,
	[NetDisposableIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BankLoans] [int] NULL,
	[LoansFromFinancialInstitutions] [int] NULL,
	[DaysOverdue] [int] NULL,
	[Property] [int] NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MonthlyIncomeNSSI_Amount] [decimal](16, 2) NULL,
	[MonthlyIncomeNSSI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[MonthlyLeasePayment] [decimal](16, 2) NULL,
	[DaysOverdueRange] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[MonthsWithEmployment] [int] NOT NULL,
	[PartyId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DNAParametersForCreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionForCreditApplication_DNAParametersForCreditDecisions] FOREIGN KEY([CreditDecisionForCreditApplicationId])
REFERENCES [dbo].[CreditDecisionForCreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DNAParametersForCreditDecisions] CHECK CONSTRAINT [ECreditDecisionForCreditApplication_DNAParametersForCreditDecisions]
GO
ALTER TABLE [dbo].[DNAParametersForCreditDecisions]  WITH CHECK ADD  CONSTRAINT [EDNAParametersForCreditDecision_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[DNAParametersForCreditDecisions] CHECK CONSTRAINT [EDNAParametersForCreditDecision_Party]
GO
