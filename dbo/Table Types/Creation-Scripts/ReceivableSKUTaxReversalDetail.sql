CREATE TYPE [dbo].[ReceivableSKUTaxReversalDetail] AS TABLE(
	[Revenue_Amount] [decimal](16, 2) NOT NULL,
	[Revenue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountBilledToDate_Amount] [decimal](16, 2) NOT NULL,
	[AmountBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[ReceivableTaxDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO