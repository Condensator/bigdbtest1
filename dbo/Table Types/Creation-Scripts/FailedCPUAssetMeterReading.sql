CREATE TYPE [dbo].[FailedCPUAssetMeterReading] AS TABLE(
	[EndPeriodDate] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[ReadDate] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[CPINumber] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NULL,
	[Alias] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SerialNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MeterType] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[BeginReading] [bigint] NULL,
	[EndReading] [bigint] NULL,
	[ServiceCredits] [bigint] NULL,
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[IsEstimated] [bit] NULL,
	[MeterResetType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FailureReason] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL
)
GO
