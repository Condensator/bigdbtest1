SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSalesTradeIns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[VATType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[ProjectedVATAmount_Amount] [decimal](16, 2) NULL,
	[ProjectedVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[TaxCodeRateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSalesTradeIns]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSalesTradeIns] FOREIGN KEY([AssetSaleId])
REFERENCES [dbo].[AssetSales] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSalesTradeIns] CHECK CONSTRAINT [EAssetSale_AssetSalesTradeIns]
GO
ALTER TABLE [dbo].[AssetSalesTradeIns]  WITH CHECK ADD  CONSTRAINT [EAssetSalesTradeIn_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSalesTradeIns] CHECK CONSTRAINT [EAssetSalesTradeIn_Asset]
GO
ALTER TABLE [dbo].[AssetSalesTradeIns]  WITH CHECK ADD  CONSTRAINT [EAssetSalesTradeIn_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetSalesTradeIns] CHECK CONSTRAINT [EAssetSalesTradeIn_TaxCode]
GO
ALTER TABLE [dbo].[AssetSalesTradeIns]  WITH CHECK ADD  CONSTRAINT [EAssetSalesTradeIn_TaxCodeRate] FOREIGN KEY([TaxCodeRateId])
REFERENCES [dbo].[TaxCodeRates] ([Id])
GO
ALTER TABLE [dbo].[AssetSalesTradeIns] CHECK CONSTRAINT [EAssetSalesTradeIn_TaxCodeRate]
GO
ALTER TABLE [dbo].[AssetSalesTradeIns]  WITH CHECK ADD  CONSTRAINT [EAssetSalesTradeIn_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetSalesTradeIns] CHECK CONSTRAINT [EAssetSalesTradeIn_TaxType]
GO
