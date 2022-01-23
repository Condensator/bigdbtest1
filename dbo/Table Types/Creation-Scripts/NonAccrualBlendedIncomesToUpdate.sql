CREATE TYPE [dbo].[NonAccrualBlendedIncomesToUpdate] AS TABLE(
	[Id] [bigint] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL
)
GO
