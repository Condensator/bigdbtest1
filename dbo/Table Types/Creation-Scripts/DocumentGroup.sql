CREATE TYPE [dbo].[DocumentGroup] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AutoImportForEntity] [bit] NOT NULL,
	[RuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsReadyToUse] [bit] NOT NULL,
	[AutoEmail] [bit] NOT NULL,
	[IsCreditDecision] [bit] NOT NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
