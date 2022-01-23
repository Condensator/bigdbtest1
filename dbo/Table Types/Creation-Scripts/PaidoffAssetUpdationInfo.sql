CREATE TYPE [dbo].[PaidoffAssetUpdationInfo] AS TABLE(
	[AssetId] [bigint] NULL,
	[Status] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayoffAssetStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[PlaceholderAssetId] [bigint] NULL,
	[RemarketingVendorId] [bigint] NULL,
	[RepossessionAgentId] [bigint] NULL,
	[IsAssetDroppedOff] [bit] NULL,
	[DropOffLocationId] [bigint] NULL,
	[DropOffDate] [datetime] NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepGLTemplateId] [bigint] NULL,
	[ProspectiveContract] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL
)
GO
