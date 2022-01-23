CREATE TYPE [dbo].[ImpairmentDetailPVUpdateTableType] AS TABLE(
	[AssetId] [bigint] NULL,
	[PVAmount] [decimal](18, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL
)
GO
