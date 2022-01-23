CREATE TYPE [dbo].[PartyContactTypePreference] AS TABLE(
	[Id] [bigint] NOT NULL,
	[ContactType] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
