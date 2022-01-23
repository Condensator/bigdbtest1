CREATE TYPE [dbo].[AMLRiskAssessment] AS TABLE(
	[FinalDecision] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntryDate] [date] NULL,
	[Entity] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[InformationOnlyText] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[PartyContactId] [bigint] NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
