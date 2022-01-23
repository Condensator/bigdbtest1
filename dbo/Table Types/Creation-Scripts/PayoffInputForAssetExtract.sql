CREATE TYPE [dbo].[PayoffInputForAssetExtract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[CommencementDate] [date] NOT NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
	[IsOperatingLease] [bit] NOT NULL,
	[IsChargedOffLease] [bit] NOT NULL,
	[SyndicationType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SyndicationEffectiveDate] [date] NULL,
	[LessorRetainedPercentage] [decimal](18, 8) NULL,
	[MaturityDate] [date] NOT NULL
)
GO
