CREATE TYPE [dbo].[AssetValueHistoryType] AS TABLE(
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetValue_Amount] [decimal](19, 2) NULL,
	[AssetValue_Currency] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[ValueHistorySourceModule] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IncomeDate] [datetime] NULL
)
GO
