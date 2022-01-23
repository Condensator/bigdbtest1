CREATE TYPE [dbo].[CCRReportDelinquency] AS TABLE(
	[LoanType] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Year] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CategoryofDelinquency] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NumberofAccountingPeriods] [decimal](16, 2) NULL,
	[NumberofLoans] [decimal](16, 2) NULL,
	[OverduePrincipalOutstanding_Amount] [decimal](16, 2) NULL,
	[OverduePrincipalOutstanding_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OverdueInterestAndOtherReceivables_Amount] [decimal](16, 2) NULL,
	[OverdueInterestAndOtherReceivables_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalOffBalanceExp_Amount] [decimal](16, 2) NULL,
	[TotalOffBalanceExp_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DateofCorrection] [date] NULL,
	[FinancialInstitution] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[DNAParametersForCreditDecisionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
