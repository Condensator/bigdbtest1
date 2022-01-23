CREATE TYPE [dbo].[MeterReadingInfo] AS TABLE(
	[CPUContractSequenceNumber] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[CPUScheduleNumber] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[CPUAssetId] [bigint] NULL,
	[EffectiveFrom] [datetime] NOT NULL
)
GO
