CREATE TYPE [dbo].[RACRuleConfig] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[RuleExpression] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ParameterLabel] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemControlled] [bit] NOT NULL,
	[NullDefaultValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BusinessDeclineReasonCodeConfigId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
