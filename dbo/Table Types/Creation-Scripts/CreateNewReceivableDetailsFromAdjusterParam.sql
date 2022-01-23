CREATE TYPE [dbo].[CreateNewReceivableDetailsFromAdjusterParam] AS TABLE(
	[ReceivableTempId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[Amount] [decimal](16, 2) NULL,
	[AssetId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[AdjustmentReceivableDetailId] [bigint] NULL,
	[AssetComponentType] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	INDEX [IX_ReceivableId] NONCLUSTERED 
(
	[ReceivableId] ASC
)
)
GO
