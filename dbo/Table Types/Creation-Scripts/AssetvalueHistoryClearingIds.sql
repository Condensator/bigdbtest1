CREATE TYPE [dbo].[AssetvalueHistoryClearingIds] AS TABLE(
	[Id] [bigint] NULL,
	[NetValue_Amount] [decimal](18, 0) NULL,
	[NetValue_Currency] [nvarchar](1) COLLATE Latin1_General_CI_AS NULL,
	[IsCleared] [bit] NULL
)
GO
