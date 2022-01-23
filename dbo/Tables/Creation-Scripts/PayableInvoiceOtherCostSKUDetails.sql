SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceOtherCostSKUDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OtherCost_Amount] [decimal](16, 2) NOT NULL,
	[OtherCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceAssetSKUId] [bigint] NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostSKUDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_PayableInvoiceOtherCostSKUDetails] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostSKUDetails] CHECK CONSTRAINT [EPayableInvoiceOtherCost_PayableInvoiceOtherCostSKUDetails]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostSKUDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCostSKUDetail_PayableInvoiceAssetSKU] FOREIGN KEY([PayableInvoiceAssetSKUId])
REFERENCES [dbo].[PayableInvoiceAssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostSKUDetails] CHECK CONSTRAINT [EPayableInvoiceOtherCostSKUDetail_PayableInvoiceAssetSKU]
GO
