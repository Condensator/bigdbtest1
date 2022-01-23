CREATE TYPE [dbo].[RepaymentSchedulesToBeUpdated] AS TABLE(
	[RepaymentScheduleId] [bigint] NULL,
	[EffectivePrincipalBalance] [decimal](16, 2) NULL,
	[EffectiveExpenseBalance] [decimal](16, 2) NULL,
	[PrincipalBookBalance] [decimal](16, 2) NULL,
	[ExpenseBookBalance] [decimal](16, 2) NULL,
	[IsApportioned] [bit] NULL
)
GO
