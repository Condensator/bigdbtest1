CREATE TYPE [dbo].[DiscountingAmortToCreate] AS TABLE(
	[Key] [bigint] NULL,
	[ExpenseDate] [date] NOT NULL,
	[PaymentAmount] [decimal](16, 2) NOT NULL,
	[BeginNetBookValue] [decimal](16, 2) NOT NULL,
	[EndNetBookValue] [decimal](16, 2) NOT NULL,
	[PrincipalRepaid] [decimal](16, 2) NOT NULL,
	[PrincipalAdded] [decimal](16, 2) NOT NULL,
	[InterestPayment] [decimal](16, 2) NOT NULL,
	[InterestAccrued] [decimal](16, 2) NOT NULL,
	[InterestAccrualBalance] [decimal](16, 2) NOT NULL,
	[InterestRate] [decimal](14, 9) NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[CapitalizedInterest] [decimal](16, 2) NOT NULL,
	[PrincipalGainLoss] [decimal](16, 2) NOT NULL,
	[InterestGainLoss] [decimal](16, 2) NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL
)
GO
