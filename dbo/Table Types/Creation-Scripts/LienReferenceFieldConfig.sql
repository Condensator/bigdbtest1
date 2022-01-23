CREATE TYPE [dbo].[LienReferenceFieldConfig] AS TABLE(
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FieldName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[FieldExpression] [nvarchar](2000) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExecutionOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
