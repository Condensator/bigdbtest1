CREATE TYPE [dbo].[LeaseAssetInput] AS TABLE(
	[AssetId] [bigint] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[NBV] [decimal](16, 2) NULL,
	[RENT] [decimal](16, 2) NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL
)
GO
