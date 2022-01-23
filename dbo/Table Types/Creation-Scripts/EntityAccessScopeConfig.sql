CREATE TYPE [dbo].[EntityAccessScopeConfig] AS TABLE(
	[Condition] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccessScope] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccessScopeExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
