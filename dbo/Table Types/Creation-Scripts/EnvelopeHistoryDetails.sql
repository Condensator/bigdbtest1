CREATE TYPE [dbo].[EnvelopeHistoryDetails] AS TABLE(
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Activity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Date] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ExternalId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL
)
GO
