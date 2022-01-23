SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceDepositAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DepositAssetId] [bigint] NOT NULL,
	[PayableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceDepositAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_PayableInvoiceDepositAssets] FOREIGN KEY([PayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceDepositAssets] CHECK CONSTRAINT [EPayableInvoice_PayableInvoiceDepositAssets]
GO
ALTER TABLE [dbo].[PayableInvoiceDepositAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceDepositAsset_DepositAsset] FOREIGN KEY([DepositAssetId])
REFERENCES [dbo].[PayableInvoiceAssets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceDepositAssets] CHECK CONSTRAINT [EPayableInvoiceDepositAsset_DepositAsset]
GO
