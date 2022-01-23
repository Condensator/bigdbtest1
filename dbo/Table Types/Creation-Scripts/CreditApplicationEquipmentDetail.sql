CREATE TYPE [dbo].[CreditApplicationEquipmentDetail] AS TABLE(
	[Number] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Quantity] [bigint] NOT NULL,
	[TotalCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[IsNewLocation] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsFromQuote] [bit] NOT NULL,
	[VATAmount_Amount] [decimal](16, 2) NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DateOfProduction] [date] NOT NULL,
	[AgeofAsset] [decimal](16, 2) NOT NULL,
	[KW] [decimal](16, 2) NULL,
	[EngineCapacity] [decimal](16, 2) NULL,
	[IsVAT] [bit] NOT NULL,
	[ValueInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EquipmentDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsImported] [bit] NULL,
	[TechnicallyPermissibleMass] [decimal](16, 2) NULL,
	[LoadCapacity] [decimal](16, 2) NULL,
	[Seats] [int] NULL,
	[InsuranceAssessment_Amount] [decimal](16, 2) NOT NULL,
	[InsuranceAssessment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProgramAssetTypeId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[EquipmentVendorId] [bigint] NULL,
	[PricingGroupId] [bigint] NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[MakeId] [bigint] NOT NULL,
	[ModelId] [bigint] NOT NULL,
	[AssetClassConfigId] [bigint] NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
