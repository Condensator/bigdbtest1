CREATE TYPE [dbo].[CourtFilingParty] AS TABLE(
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DateServed] [date] NULL,
	[AnswerDeadlineDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsMainParty] [bit] NOT NULL,
	[PartyTypes] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[ThirdPartyRelationshipId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[RelatedCustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
