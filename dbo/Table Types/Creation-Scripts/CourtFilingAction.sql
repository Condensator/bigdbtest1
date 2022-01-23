CREATE TYPE [dbo].[CourtFilingAction] AS TABLE(
	[LegalReliefType] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalAction] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionType] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActionStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[FilingDate] [date] NULL,
	[DeadlineDate] [date] NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[RelatedLegalActionId] [bigint] NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
