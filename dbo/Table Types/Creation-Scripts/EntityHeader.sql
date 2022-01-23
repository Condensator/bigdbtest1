CREATE TYPE [dbo].[EntityHeader] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntitySummary] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AccessScope] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccessScopeId] [bigint] NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
