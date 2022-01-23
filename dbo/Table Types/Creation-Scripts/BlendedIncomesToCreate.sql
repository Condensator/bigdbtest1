CREATE TYPE [dbo].[BlendedIncomesToCreate] AS TABLE(
	[IncomeDate] [date] NULL,
	[Income] [decimal](16, 2) NOT NULL,
	[IncomeBalance] [decimal](16, 2) NOT NULL,
	[EffectiveYield] [decimal](28, 18) NULL,
	[EffectiveInterest] [decimal](16, 2) NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[ModificationType] [nvarchar](25) COLLATE Latin1_General_CI_AS NULL,
	[ModificationId] [bigint] NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[NonAccrualPostDate] [date] NULL,
	[UniqueId] [bigint] NULL
)
GO
