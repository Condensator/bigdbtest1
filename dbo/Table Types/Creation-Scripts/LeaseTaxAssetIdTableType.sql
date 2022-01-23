CREATE TYPE [dbo].[LeaseTaxAssetIdTableType] AS TABLE(
	[Id] [bigint] NULL,
	[IsRental] [bit] NULL,
	[ReceivableCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LeaseTaxAssetId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetCollateralCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CityTaxTypeId] [bigint] NULL,
	[StateTaxtypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[AcquisitionLocationId] [bigint] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL
)
GO
