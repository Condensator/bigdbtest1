CREATE TYPE [dbo].[ReceivableTaxImpositionParameters] AS TABLE(
	[ExemptionType] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExemptionRate] [decimal](10, 6) NOT NULL,
	[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
	[ExemptionAmount_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxableBasisAmount_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[AppliedTaxRate] [decimal](10, 6) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalTaxImpositionType] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[TaxTypeId] [bigint] NULL,
	[ExternalJurisdictionLevelId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxBasisType] [nvarchar](80) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL
)
GO