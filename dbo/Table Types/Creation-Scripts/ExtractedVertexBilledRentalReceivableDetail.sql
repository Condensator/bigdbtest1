CREATE TYPE [dbo].[ExtractedVertexBilledRentalReceivableDetail] AS TABLE(
	[RevenueBilledToDate_Amount] [decimal](16, 2) NOT NULL,
	[RevenueBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CumulativeAmount_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[AssetSKUId] [bigint] NULL
)
GO
