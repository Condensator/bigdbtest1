CREATE TYPE [dbo].[CreditDecisionScoreCard] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalScore] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FinalRating] [int] NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
