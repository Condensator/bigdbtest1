CREATE TYPE [dbo].[ReceivableDetail] AS TABLE(
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBookBalance_Amount] [decimal](16, 2) NULL,
	[EffectiveBookBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[BilledStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsTaxAssessed] [bit] NOT NULL,
	[StopInvoicing] [bit] NOT NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[LeaseComponentAmount_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentAmount_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentBalance_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentBalance_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreCapitalizationRent_Amount] [decimal](16, 2) NOT NULL,
	[PreCapitalizationRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
