CREATE TYPE [dbo].[ReceivableTaxDetailsToAdjust] AS TABLE(
	[OldReceivableId] [bigint] NULL,
	[NewReceivableId] [bigint] NULL,
	[OldReceivableDetailId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[NewReceivableDetailId] [bigint] NULL,
	[IsVATReceivable] [bit] NULL
)
GO
