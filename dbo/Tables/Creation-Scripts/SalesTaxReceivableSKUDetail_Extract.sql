SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesTaxReceivableSKUDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
