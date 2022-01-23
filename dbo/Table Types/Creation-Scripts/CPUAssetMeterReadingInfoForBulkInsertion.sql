CREATE TYPE [dbo].[CPUAssetMeterReadingInfoForBulkInsertion] AS TABLE(
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[RowId] [bigint] NOT NULL,
	[CreatedById] [bigint] NULL,
	[CreatedTime] [datetimeoffset](7) NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BeginPeriodDate] [date] NOT NULL,
	[EndPeriodDate] [date] NOT NULL,
	[ReadDate] [date] NOT NULL,
	[BeginReading] [bigint] NOT NULL,
	[EndReading] [bigint] NOT NULL,
	[Reading] [bigint] NOT NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[IsCorrection] [bit] NOT NULL,
	[IsMeterReset] [bit] NOT NULL,
	[MeterResetType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[LinkedCPUAssetMeterReadingId] [bigint] NULL,
	[LinkedCPUAssetMeterReadingRowId] [bigint] NULL,
	[CPUAssetId] [bigint] NULL,
	[CPUAssetMeterReadingHeaderId] [bigint] NOT NULL,
	[CPUOverageAssessmentId] [bigint] NULL,
	[AssessmentEffectiveDate] [date] NOT NULL
)
GO
