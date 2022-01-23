CREATE TYPE [dbo].[ResourceEntryCollection] AS TABLE(
	[Id] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EntityType] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Culture] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Name] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Value] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL
)
GO
