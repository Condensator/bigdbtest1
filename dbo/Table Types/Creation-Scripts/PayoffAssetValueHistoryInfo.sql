CREATE TYPE [dbo].[PayoffAssetValueHistoryInfo] AS TABLE(
	[AssetId] [bigint] NULL,
	[Value] [decimal](16, 2) NULL,
	[NetValue] [decimal](16, 2) NULL,
	[Cost] [decimal](16, 2) NULL,
	[BeginBookValue] [decimal](16, 2) NULL,
	[EndBookValue] [decimal](16, 2) NULL,
	[IsLessorOwned] [bit] NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
