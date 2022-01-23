CREATE TYPE [dbo].[DocumentEmailContact] AS TABLE(
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContactName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ContactType] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
