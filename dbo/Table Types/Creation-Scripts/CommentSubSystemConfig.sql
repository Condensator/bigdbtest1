CREATE TYPE [dbo].[CommentSubSystemConfig] AS TABLE(
	[IsEnabledInUI] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EnableRuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[SubSystemId] [bigint] NOT NULL,
	[CommentEntityConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
