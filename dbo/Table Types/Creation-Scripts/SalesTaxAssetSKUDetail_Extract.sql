CREATE TYPE [dbo].[SalesTaxAssetSKUDetail_Extract] AS TABLE(
	[AssetSKUId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[NBVAmount] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
