SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableSKUTaxReversalDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Revenue_Amount] [decimal](16, 2) NOT NULL,
	[Revenue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetSKUId] [bigint] NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[ReceivableTaxDetailId] [bigint] NOT NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[AmountBilledToDate_Amount] [decimal](16, 2) NOT NULL,
	[AmountBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableSKUTaxReversalDetail_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails] CHECK CONSTRAINT [EReceivableSKUTaxReversalDetail_AssetSKU]
GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableSKUTaxReversalDetail_ReceivableSKU] FOREIGN KEY([ReceivableSKUId])
REFERENCES [dbo].[ReceivableSKUs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails] CHECK CONSTRAINT [EReceivableSKUTaxReversalDetail_ReceivableSKU]
GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_ReceivableSKUTaxReversalDetails] FOREIGN KEY([ReceivableTaxDetailId])
REFERENCES [dbo].[ReceivableTaxDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableSKUTaxReversalDetails] CHECK CONSTRAINT [EReceivableTaxDetail_ReceivableSKUTaxReversalDetails]
GO
