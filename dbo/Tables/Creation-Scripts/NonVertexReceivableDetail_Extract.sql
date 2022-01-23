SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonVertexReceivableDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[TaxTypeId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[LocationId] [bigint] NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[AssetCost] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxMode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[StateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousStateShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsUpFrontApplicable] [bit] NOT NULL,
	[ClassCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JurisdictionId] [bigint] NOT NULL,
	[TaxBasisType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[StateTaxTypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL,
	[CityTaxTypeId] [bigint] NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[IsCapitalizedSalesTaxAsset] [bit] NOT NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsCapitalizedRealAsset] [bit] NOT NULL,
	[GLTemplateId] [bigint] NULL,
	[IsCapitalizedFirstRealAsset] [bit] NOT NULL,
	[CommencementDate] [date] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CountryShortName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsCashBased] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
