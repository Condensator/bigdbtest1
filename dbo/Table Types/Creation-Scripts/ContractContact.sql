CREATE TYPE [dbo].[ContractContact] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewAddress] [bit] NOT NULL,
	[IsNewContact] [bit] NOT NULL,
	[IsSignatory] [bit] NULL,
	[PartyAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
