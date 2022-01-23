CREATE TYPE [dbo].[DocumentSubSystemConfig] AS TABLE(
	[GenerationAllowed] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GenerationAllowedExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsEnabledInUI] [bit] NOT NULL,
	[EnableRuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[PhrasesAllowed] [bit] NOT NULL,
	[SubSystemId] [bigint] NOT NULL,
	[DocumentEntityConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
