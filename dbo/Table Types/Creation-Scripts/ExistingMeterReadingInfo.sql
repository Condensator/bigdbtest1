CREATE TYPE [dbo].[ExistingMeterReadingInfo] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[BeginPeriodDate] [date] NOT NULL,
	[EndPeriodDate] [date] NOT NULL,
	[EndReading] [bigint] NOT NULL,
	[Reading] [bigint] NOT NULL,
	[ServiceCredits] [bigint] NOT NULL,
	[CPUAssetId] [bigint] NULL,
	[CPUOverageAssessmentId] [bigint] NULL,
	[AssessmentEffectiveDate] [date] NOT NULL,
	[IsEstimated] [bit] NOT NULL,
	[Source] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL
)
GO
