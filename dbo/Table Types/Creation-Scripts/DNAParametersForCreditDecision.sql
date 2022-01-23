CREATE TYPE [dbo].[DNAParametersForCreditDecision] AS TABLE(
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MonthlyIncomeNSSI_Amount] [decimal](16, 2) NULL,
	[MonthlyIncomeNSSI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetDisposableIncome_Amount] [decimal](16, 2) NULL,
	[NetDisposableIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[MonthlyLeasePayment] [decimal](16, 2) NULL,
	[BankLoans] [int] NULL,
	[LoansFromFinancialInstitutions] [int] NULL,
	[DaysOverdue] [int] NULL,
	[DaysOverdueRange] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Property] [int] NULL,
	[MonthsWithEmployment] [int] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
