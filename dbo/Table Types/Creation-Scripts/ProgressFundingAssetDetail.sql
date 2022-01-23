CREATE TYPE [dbo].[ProgressFundingAssetDetail] AS TABLE(
	[PayableInvoiceAssetId] [bigint] NULL,
	[CollateralAssetActiveStatus] [bit] NULL,
	[TerminationDate] [datetime] NULL
)
GO
