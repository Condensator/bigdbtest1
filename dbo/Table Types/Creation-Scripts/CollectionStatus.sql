CREATE TYPE [dbo].[CollectionStatus] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssignmentMethod] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleExpression] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
