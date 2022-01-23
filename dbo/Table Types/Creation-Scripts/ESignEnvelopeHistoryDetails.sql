CREATE TYPE [dbo].[ESignEnvelopeHistoryDetails] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Activity] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Date] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalId] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
