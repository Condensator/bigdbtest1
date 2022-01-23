CREATE TYPE [dbo].[CourtFilingActionsLegalEntity] AS TABLE(
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
