CREATE TYPE [dbo].[ExtractedVertexWSTransaction] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[DueDate] [date] NULL,
	[LeaseUniqueID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NULL
)
GO
