CREATE TYPE [dbo].[DocumentEntityRelationConfig] AS TABLE(
	[RelationshipType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NavigationPathFromRootEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsPartialEntity] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NavigationPathToRootEntity] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[RootEntityId] [bigint] NOT NULL,
	[RelatedEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
