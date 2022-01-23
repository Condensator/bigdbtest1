CREATE TYPE [dbo].[PropertyTaxExportOneSourceAssets] AS TABLE(
	[AssetId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[IsIncluded] [bit] NULL,
	[RejectReason] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AsOfDate] [date] NULL,
	[IsDisposedAssetReported] [bit] NULL,
	[PreviousLeaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL
)
GO
