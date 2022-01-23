CREATE TYPE [dbo].[CollectionQueue] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RuleExpression] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssignmentMethod] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerAssignmentRuleExpression] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AcrossQueue] [bit] NOT NULL,
	[PrimaryCollectionGroupId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
