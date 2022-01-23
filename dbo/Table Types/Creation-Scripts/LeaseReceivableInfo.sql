CREATE TYPE [dbo].[LeaseReceivableInfo] AS TABLE(
	[AssetId] [bigint] NULL,
	[StartDate] [date] NULL,
	[Amount] [decimal](16, 2) NOT NULL
)
GO
