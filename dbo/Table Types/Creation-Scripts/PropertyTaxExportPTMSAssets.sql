CREATE TYPE [dbo].[PropertyTaxExportPTMSAssets] AS TABLE(
	[AssetId] [bigint] NULL,
	[IsIncluded] [bit] NULL,
	[AssetLocationId] [bigint] NULL,
	[RejectReason] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[LienDate] [date] NULL,
	[ContractId] [bigint] NULL,
	[AsOfDate] [date] NULL,
	[ExclusionCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsDisposedAssetReported] [bit] NULL,
	[IsTransferAsset] [bit] NULL,
	[PreviousLeaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL
)
GO
