CREATE TYPE [dbo].[InsuranceDetail] AS TABLE(
	[Number] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InsuranceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Internal] [bit] NOT NULL,
	[Frequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[EngineCapacity] [decimal](16, 2) NOT NULL,
	[VehicleAge] [int] NOT NULL,
	[InsurancePremium_Amount] [decimal](16, 2) NOT NULL,
	[InsurancePremium_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NULL,
	[InsuranceCompanyId] [bigint] NOT NULL,
	[InsuranceAgencyId] [bigint] NOT NULL,
	[RegionConfigId] [bigint] NOT NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[QuoteId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
