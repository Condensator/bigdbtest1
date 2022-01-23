CREATE TYPE [dbo].[LegalEntitiesForUser] AS TABLE(
	[ActivationDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsDefault] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
