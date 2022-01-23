CREATE TYPE [dbo].[FlatFee] AS TABLE(
	[PermissibleMassFrom] [decimal](16, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissibleMassTill] [decimal](16, 2) NULL,
	[SeatFrom] [int] NULL,
	[SeatTill] [int] NULL,
	[EnginecapacityFrom] [decimal](16, 2) NULL,
	[EngineCapacityTill] [decimal](16, 2) NULL,
	[LoadCapacity] [decimal](16, 2) NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
