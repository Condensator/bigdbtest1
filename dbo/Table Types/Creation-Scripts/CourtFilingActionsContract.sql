CREATE TYPE [dbo].[CourtFilingActionsContract] AS TABLE(
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Role] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeletedRecord] [bit] NOT NULL,
	[ContractId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
