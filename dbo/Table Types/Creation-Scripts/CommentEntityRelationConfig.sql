CREATE TYPE [dbo].[CommentEntityRelationConfig] AS TABLE(
	[RelationshipType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NavigationPath] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsPartialEntity] [bit] NOT NULL,
	[RelateAutomatically] [bit] NOT NULL,
	[RootEntityId] [bigint] NOT NULL,
	[RelatedEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
