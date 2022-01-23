CREATE TYPE [dbo].[CreditProfileSyndicationFundingSource] AS TABLE(
	[ParticipationPercentage] [decimal](18, 8) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[FunderId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
