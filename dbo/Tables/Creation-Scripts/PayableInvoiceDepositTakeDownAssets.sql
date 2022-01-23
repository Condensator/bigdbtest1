SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceDepositTakeDownAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TakeDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[TakeDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TakeDownAssetId] [bigint] NOT NULL,
	[NegativeDepositAssetId] [bigint] NULL,
	[PayableInvoiceDepositAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceDepositAsset_PayableInvoiceDepositTakeDownAssets] FOREIGN KEY([PayableInvoiceDepositAssetId])
REFERENCES [dbo].[PayableInvoiceDepositAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets] CHECK CONSTRAINT [EPayableInvoiceDepositAsset_PayableInvoiceDepositTakeDownAssets]
GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceDepositTakeDownAsset_NegativeDepositAsset] FOREIGN KEY([NegativeDepositAssetId])
REFERENCES [dbo].[PayableInvoiceAssets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets] CHECK CONSTRAINT [EPayableInvoiceDepositTakeDownAsset_NegativeDepositAsset]
GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceDepositTakeDownAsset_TakeDownAsset] FOREIGN KEY([TakeDownAssetId])
REFERENCES [dbo].[PayableInvoiceAssets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceDepositTakeDownAssets] CHECK CONSTRAINT [EPayableInvoiceDepositTakeDownAsset_TakeDownAsset]
GO
