CREATE TYPE [dbo].[SyndicationReceivableDetailsToSave] AS TABLE(
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBookBalance_Amount] [decimal](16, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[BilledStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsTaxAssessed] [bit] NOT NULL,
	[StopInvoicing] [bit] NOT NULL,
	[AssetId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentAmount_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentBalance_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponenAmount_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponenBalance_Amount] [decimal](16, 2) NOT NULL,
	[PreCapitalizationRent_Amount] [decimal](16, 2) NOT NULL
)
GO
