CREATE TYPE [dbo].[AccrualDetailsInputInfo] AS TABLE(
	[DiscountingId] [bigint] NULL,
	[NonAccrualDate] [date] NULL,
	[ReAccrualDate] [date] NULL,
	[PostDate] [date] NULL,
	[SourceId] [bigint] NULL
)
GO
