CREATE TYPE [dbo].[MeterReadingInactivationInfo] AS TABLE(
	[ContractSequenceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ScheduleNumber] [bigint] NULL,
	[CPUAssetId] [bigint] NULL,
	[EffectiveDate] [datetime] NOT NULL
)
GO
