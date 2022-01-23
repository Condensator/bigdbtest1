CREATE TYPE [dbo].[StoredProcMessage] AS TABLE(
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[ParameterValuesCsv] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL
)
GO
