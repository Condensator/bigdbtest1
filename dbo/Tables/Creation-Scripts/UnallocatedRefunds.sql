SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnallocatedRefunds](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PayableDate] [date] NULL,
	[Memo] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmountToClear_Amount] [decimal](16, 2) NULL,
	[AmountToClear_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NULL,
	[TYPE] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
	[DiscountingId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Contract]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_CostCenter]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Currency]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Customer]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Discounting]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_InstrumentType]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_LegalEntity]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_LineofBusiness]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_PayableCode]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_PayableRemitTo]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Receipt]
GO
ALTER TABLE [dbo].[UnallocatedRefunds]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefunds] CHECK CONSTRAINT [EUnallocatedRefund_Vendor]
GO
