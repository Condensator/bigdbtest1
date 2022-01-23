CREATE TYPE [dbo].[MTPLConfig] AS TABLE(
	[RegionId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EngineCapacityFrom] [decimal](16, 2) NOT NULL,
	[EngineCapacityTo] [decimal](16, 2) NOT NULL,
	[PermissibleMassFrom] [decimal](16, 2) NULL,
	[PermissibleMassTo] [decimal](16, 2) NULL,
	[SeatsFrom] [int] NULL,
	[SeatsTo] [int] NULL,
	[Frequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[InsurancePremium_Amount] [decimal](16, 2) NOT NULL,
	[InsurancePremium_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
