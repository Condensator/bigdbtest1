SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetMeasures](
	[Id] [bigint] NOT NULL,
	[RemainingEconomicLife] [int] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NBVImpairment] [decimal](16, 2) NULL,
	[AccumulatedNBVImpairmentAmountLeaseComponent] [decimal](16, 2) NULL,
	[AccumulatedNBVImpairmentAmountFinanceComponent] [decimal](16, 2) NULL,
	[ResidualImpairmentAmountLeaseComponent] [decimal](16, 2) NULL,
	[ResidualImpairmentAmountFinanceComponent] [decimal](16, 2) NULL,
	[AssetImpairmentLeaseComponent] [decimal](16, 2) NULL,
	[AssetImpairmentFinanceComponent] [decimal](16, 2) NULL,
	[AccumulatedAssetImpairmentAmountLeaseComponent] [decimal](16, 2) NULL,
	[AccumulatedAssetImpairmentAmountFinanceComponent] [decimal](16, 2) NULL,
	[AcquisitionCostLeaseComponent] [decimal](16, 2) NULL,
	[AcquisitionCostFinanceComponent] [decimal](16, 2) NULL,
	[AccumulatedInventoryDepreciationAmountLeaseComponent] [decimal](16, 2) NULL,
	[AccumulatedInventoryDepreciationAmountFinanceComponent] [decimal](16, 2) NULL,
	[AccumulatedFixedTermDepreciationAmountLeaseComponent] [decimal](16, 2) NULL,
	[AccumulatedOTPDepreciationAmountLeaseComponent] [decimal](16, 2) NULL,
	[AccumulatedOTPDepreciationAmountFinanceComponent] [decimal](16, 2) NULL,
	[CurrentNBVAmountLeaseComponent] [decimal](16, 2) NULL,
	[CurrentNBVAmountFinanceComponent] [decimal](16, 2) NULL,
	[AssetValue] [decimal](16, 2) NULL,
	[DatePlacedOffInventory] [date] NULL,
	[DatePlacedInInventory] [date] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetMeasures]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetMeasures] FOREIGN KEY([Id])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetMeasures] CHECK CONSTRAINT [EAsset_AssetMeasures]
GO
