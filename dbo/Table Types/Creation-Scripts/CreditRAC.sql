CREATE TYPE [dbo].[CreditRAC] AS TABLE(
	[Result] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Use] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BusinessDeclineReasonCode] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RACId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
