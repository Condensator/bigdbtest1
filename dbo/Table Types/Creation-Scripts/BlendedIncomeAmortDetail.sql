CREATE TYPE [dbo].[BlendedIncomeAmortDetail] AS TABLE(
	[IncomeDate] [datetime] NULL,
	[Income] [decimal](16, 2) NULL,
	[IncomeBalance] [decimal](16, 2) NULL,
	[BlendedItemId] [bigint] NULL,
	[IsAccounting] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[IsAdjustmentEntry] [bit] NULL,
	[IsNonAccrual] [bit] NULL,
	[PostDate] [datetime] NULL
)
GO
