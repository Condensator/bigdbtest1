CREATE TYPE [dbo].[ReceivableTaxSKUImpositionParameter] AS TABLE(
	[ExemptionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ExemptionRate] [decimal](10, 6) NOT NULL,
	[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
	[ExemptionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxableBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AppliedTaxRate] [decimal](10, 6) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalTaxImpositionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TaxTypeId] [bigint] NULL,
	[ExternalJurisdictionLevelId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[AssetSKUId] [bigint] NULL,
	[TaxBasisType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
