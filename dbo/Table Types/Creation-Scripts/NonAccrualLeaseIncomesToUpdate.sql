CREATE TYPE [dbo].[NonAccrualLeaseIncomesToUpdate] AS TABLE(
	[Id] [bigint] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[PostDate] [date] NULL
)
GO
