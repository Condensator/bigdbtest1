CREATE TYPE [dbo].[PayOffTemplateTerminationType] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ConditionalCalculation] [bit] NOT NULL,
	[PayoffTemplateTerminationTypeConfigId] [bigint] NOT NULL,
	[PayoffTerminationExpressionId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
