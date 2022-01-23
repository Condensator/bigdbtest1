CREATE TYPE [dbo].[AssetTrueDownpaymentDistribution] AS TABLE(
	[AssetId] [bigint] NULL,
	[TrueDownPayment] [decimal](16, 2) NOT NULL
)
GO
