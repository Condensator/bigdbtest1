CREATE TYPE [dbo].[ComputedProcessThroughDate] AS TABLE(
	[EntityId] [bigint] NULL,
	[EntityType] [varchar](2) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[LeadDays] [bigint] NULL,
	[DueDay] [int] NULL,
	[ComputedProcessThroughDate] [datetime] NULL
)
GO
