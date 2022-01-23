SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteSundries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludeInPayoffInvoice] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[VendorId] [bigint] NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSalesTaxAssessed] [bit] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteSundries] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuote_PreQuoteSundries]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_BillTo]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_Contract]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_Customer]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_Location]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_PayableCode]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_PayableRemitTo]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_ReceivableCode]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[PreQuoteSundries]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSundry_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSundries] CHECK CONSTRAINT [EPreQuoteSundry_Vendor]
GO
