CREATE TYPE [dbo].[NonVertexAssetDetail_Extract] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseAssetId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[StateTaxTypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL,
	[CityTaxTypeId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PreviousSalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate] [date] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
