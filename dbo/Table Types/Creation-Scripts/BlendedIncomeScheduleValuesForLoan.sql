CREATE TYPE [dbo].[BlendedIncomeScheduleValuesForLoan] AS TABLE(
	[Id] [bigint] NULL,
	[Income] [decimal](16, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IncomeBalance] [decimal](16, 2) NULL,
	[EffectiveYield] [decimal](28, 18) NULL,
	[EffectiveInterest] [decimal](16, 2) NULL,
	[IsAccounting] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[PostDate] [date] NULL,
	[IsNonAccrual] [bit] NULL,
	[BlendedItemId] [bigint] NULL,
	[IncomeDate] [date] NULL,
	[AdjustmentEntry] [bit] NULL,
	[IsRecomputed] [bit] NULL,
	[LoanFinanceId] [bigint] NULL
)
GO
