CREATE TYPE [dbo].[SalesTaxContractBasedSplitupReceivableDetail_Extract] AS TABLE(
	[ReceivableDetailId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[CustomerCost] [decimal](16, 2) NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
