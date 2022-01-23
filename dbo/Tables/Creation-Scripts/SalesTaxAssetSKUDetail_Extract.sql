SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesTaxAssetSKUDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[LeaseAssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[NBVAmount] [decimal](16, 2) NOT NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
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
