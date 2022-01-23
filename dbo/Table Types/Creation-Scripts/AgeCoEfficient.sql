CREATE TYPE [dbo].[AgeCoEfficient] AS TABLE(
	[PermissibleMassFrom] [decimal](16, 2) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissibleMassTill] [decimal](16, 2) NOT NULL,
	[AgeFrom] [int] NOT NULL,
	[AgeTo] [int] NOT NULL,
	[CoEfficient] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
