CREATE TYPE [dbo].[GLSegmentTypeConfig] AS TABLE(
	[Value] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaximumLength] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[RuleExpression] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
