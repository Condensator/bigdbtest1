SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SundryRecurrings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FirstDueDate] [date] NOT NULL,
	[NextPaymentDate] [date] NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsAssetBased] [bit] NOT NULL,
	[PaymentDateOffset] [int] NOT NULL,
	[IsRentalBased] [bit] NOT NULL,
	[BillPastEndDate] [bit] NOT NULL,
	[NumberOfPayments] [int] NOT NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfDays] [int] NOT NULL,
	[DueDay] [int] NOT NULL,
	[TerminationDate] [date] NULL,
	[ProcessThroughDate] [date] NULL,
	[InvoiceAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[IsFinancialParametersChanged] [bit] NOT NULL,
	[IsPayableAdjusted] [bit] NOT NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsOwned] [bit] NOT NULL,
	[IsRegular] [bit] NOT NULL,
	[IsApplyAtAssetLevel] [bit] NOT NULL,
	[RegularAmount_Amount] [decimal](16, 2) NULL,
	[RegularAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[IsExternalTermination] [bit] NOT NULL,
	[Type] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[BranchId] [bigint] NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[IsVATAssessed] [bit] NOT NULL,
	[CountryId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_BillTo]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Branch]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Contract]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_CostCenter]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Country]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Currency]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Customer]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_InstrumentType]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_LegalEntity]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_LineofBusiness]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Location]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_PayableCode]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_PayableRemitTo]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_ReceivableCode]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[SundryRecurrings]  WITH CHECK ADD  CONSTRAINT [ESundryRecurring_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[SundryRecurrings] CHECK CONSTRAINT [ESundryRecurring_Vendor]
GO
