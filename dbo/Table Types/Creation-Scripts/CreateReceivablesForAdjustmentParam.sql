CREATE TYPE [dbo].[CreateReceivablesForAdjustmentParam] AS TABLE(
	[ReceivableId] [bigint] NOT NULL,
	INDEX [IX_ReceivableId] NONCLUSTERED 
(
	[ReceivableId] ASC
)
)
GO
