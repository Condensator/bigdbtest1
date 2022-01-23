CREATE TYPE [dbo].[ParentPartyRelationshipHistory] AS TABLE(
	[AssignedDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UnassignedDate] [date] NULL,
	[ParentPartyId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
