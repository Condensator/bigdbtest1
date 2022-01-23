CREATE TYPE [dbo].[BlendedIncomeScheduleDataTable] AS TABLE(
	[BlendedItemId] [bigint] NULL,
	[Income] [decimal](16, 2) NULL,
	[IncomeBalance] [decimal](16, 2) NULL,
	[IncomeDate] [date] NULL,
	[AdjustmentEntry] [bit] NULL,
	[IsAccounting] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[IsNonAccrual] [bit] NULL
)
GO
