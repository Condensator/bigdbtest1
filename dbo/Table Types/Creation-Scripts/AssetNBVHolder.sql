CREATE TYPE [dbo].[AssetNBVHolder] AS TABLE(
	[AssetId] [bigint] NULL,
	[AssetNBV_Amount] [decimal](19, 2) NULL,
	[BeginDate] [date] NULL,
	[NumberOfDays] [bigint] NULL,
	[IsLessorOwned] [bit] NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
