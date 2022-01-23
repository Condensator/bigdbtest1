SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceOtherCostDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceAssetId] [bigint] NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_PayableInvoiceOtherCostDetails] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostDetails] CHECK CONSTRAINT [EPayableInvoiceOtherCost_PayableInvoiceOtherCostDetails]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostDetails]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCostDetail_PayableInvoiceAsset] FOREIGN KEY([PayableInvoiceAssetId])
REFERENCES [dbo].[PayableInvoiceAssets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCostDetails] CHECK CONSTRAINT [EPayableInvoiceOtherCostDetail_PayableInvoiceAsset]
GO
