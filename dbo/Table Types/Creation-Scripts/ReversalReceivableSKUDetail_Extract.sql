CREATE TYPE [dbo].[ReversalReceivableSKUDetail_Extract] AS TABLE(
	[ReceivableSKUId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTaxDetailId] [bigint] NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost] [decimal](16, 2) NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
