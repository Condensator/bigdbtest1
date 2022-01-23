SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sundries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableDueDate] [date] NULL,
	[IsAssetBased] [bit] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PayableDueDate] [date] NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsOwned] [bit] NOT NULL,
	[IsAssignAtAssetLevel] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[InvoiceAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PayableId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxPortionOfPayable_Amount] [decimal](16, 2) NOT NULL,
	[TaxPortionOfPayable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[IsVATAssessed] [bit] NOT NULL,
	[CountryId] [bigint] NULL,
	[ProjectedVATAmount_Amount] [decimal](16, 2) NOT NULL,
	[ProjectedVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_BillTo]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Branch]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Contract]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_CostCenter]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Country]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Currency]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Customer]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_InstrumentType]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_LegalEntity]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_LineofBusiness]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Location]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Payable]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_PayableCode]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_PayableRemitTo]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Receivable]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_ReceivableCode]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[Sundries]  WITH CHECK ADD  CONSTRAINT [ESundry_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Sundries] CHECK CONSTRAINT [ESundry_Vendor]
GO
