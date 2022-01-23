CREATE TYPE [dbo].[CreditDecisionScoreCardDetail] AS TABLE(
	[RuleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Conditions] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Result] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreditDecisionScoreCardId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
