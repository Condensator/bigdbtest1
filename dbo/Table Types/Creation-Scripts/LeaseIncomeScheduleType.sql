CREATE TYPE [dbo].[LeaseIncomeScheduleType] AS TABLE(
	[Id] [bigint] NOT NULL,
	INDEX [IX_Id] NONCLUSTERED 
(
	[Id] ASC
)
)
GO
