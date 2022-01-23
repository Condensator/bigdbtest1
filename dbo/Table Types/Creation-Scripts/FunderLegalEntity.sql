CREATE TYPE [dbo].[FunderLegalEntity] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsApproved] [bit] NOT NULL,
	[IsOnHold] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[FunderId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
