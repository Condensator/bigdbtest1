CREATE TYPE [dbo].[SalesTaxAssetDetail_Extract] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseAssetId] [bigint] NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsCapitalizedSalesTaxAsset] [bit] NOT NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[NBVAmount] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[OriginalTaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AcquisitionLocationId] [bigint] NULL,
	[IsSKU] [bit] NOT NULL,
	[CapitalizedOriginalAssetId] [bigint] NULL,
	[IsAssetFromOldFinance] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
