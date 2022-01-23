CREATE TYPE [dbo].[ReceivableTaxReversalDetailParameter] AS TABLE(
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsExemptAtLease] [bit] NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[Company] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Product] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LeaseType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseTerm] [decimal](18, 8) NULL,
	[TitleTransferCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[AmountBilledToDate] [decimal](16, 2) NULL,
	[AssetId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ToStateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FromStateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsCapitalizeUpfrontSalesTax] [bit] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
	[BusCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL
)
GO
