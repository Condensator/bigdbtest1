CREATE TYPE [dbo].[LeaseIncomeScheduleDetails] AS TABLE(
	[LeaseIncomeScheduleId] [bigint] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[PostDate] [date] NULL
)
GO
