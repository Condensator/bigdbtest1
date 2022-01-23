CREATE TYPE [dbo].[ReverseLeaseFloatRateUpdateEntitiesParam] AS TABLE(
	[Id] [bigint] NOT NULL,
	INDEX [IX_Id] NONCLUSTERED 
(
	[Id] ASC
)
)
GO
