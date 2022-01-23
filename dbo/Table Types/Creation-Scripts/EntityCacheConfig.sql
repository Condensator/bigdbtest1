CREATE TYPE [dbo].[EntityCacheConfig] AS TABLE(
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Filter] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AlwaysCheckForLatestVersion] [bit] NOT NULL,
	[EagerLoad] [bit] NOT NULL,
	[EagerLoadPathCsv] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
