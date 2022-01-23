CREATE TYPE [dbo].[SalesTaxReceivableSKUDetail_Extract] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
