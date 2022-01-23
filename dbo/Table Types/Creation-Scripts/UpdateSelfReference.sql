CREATE TYPE [dbo].[UpdateSelfReference] AS TABLE(
	[Id] [bigint] NOT NULL,
	[Setters] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
