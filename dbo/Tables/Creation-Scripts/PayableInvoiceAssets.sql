SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AcquisitionCost_Amount] [decimal](16, 2) NOT NULL,
	[AcquisitionCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherCost_Amount] [decimal](16, 2) NULL,
	[OtherCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[InterimInterestStartDate] [date] NULL,
	[InterestUpdateLastDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[PayableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EquipmentVendorId] [bigint] NULL,
	[AcquisitionLocationId] [bigint] NULL,
	[VATAmount_Amount] [decimal](16, 2) NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[VATType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[TaxCodeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_PayableInvoiceAssets] FOREIGN KEY([PayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceAssets] CHECK CONSTRAINT [EPayableInvoice_PayableInvoiceAssets]
GO
ALTER TABLE [dbo].[PayableInvoiceAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceAsset_AcquisitionLocation] FOREIGN KEY([AcquisitionLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceAssets] CHECK CONSTRAINT [EPayableInvoiceAsset_AcquisitionLocation]
GO
ALTER TABLE [dbo].[PayableInvoiceAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceAssets] CHECK CONSTRAINT [EPayableInvoiceAsset_Asset]
GO
ALTER TABLE [dbo].[PayableInvoiceAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceAsset_EquipmentVendor] FOREIGN KEY([EquipmentVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceAssets] CHECK CONSTRAINT [EPayableInvoiceAsset_EquipmentVendor]
GO
ALTER TABLE [dbo].[PayableInvoiceAssets]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceAsset_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceAssets] CHECK CONSTRAINT [EPayableInvoiceAsset_TaxCode]
GO
