CREATE TYPE [dbo].[CollectorAssignment] AS TABLE(
	[CustomerId] [bigint] NULL,
	[AllocatedQueueId] [bigint] NULL,
	[PrimaryCollectorId] [bigint] NULL
)
GO
