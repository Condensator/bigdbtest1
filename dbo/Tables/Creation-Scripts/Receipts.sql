SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Receipts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceiptAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[ReceivedDate] [date] NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ApplyByReceivable] [bit] NOT NULL,
	[NonCashReason] [nvarchar](28) COLLATE Latin1_General_CI_AS NULL,
	[SecurityDepositLiabilityAmount_Amount] [decimal](16, 2) NULL,
	[SecurityDepositLiabilityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SecurityDepositLiabilityContractAmount_Amount] [decimal](16, 2) NULL,
	[SecurityDepositLiabilityContractAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptClassification] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFromReceiptBatch] [bit] NOT NULL,
	[ReversalDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[CreateRefund] [bit] NOT NULL,
	[PayableDate] [date] NULL,
	[DueDate] [date] NULL,
	[CheckNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CheckDate] [date] NULL,
	[NameOnCheck] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[BankAccountId] [bigint] NULL,
	[CashTypeId] [bigint] NULL,
	[TypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[ReceiptBatchId] [bigint] NULL,
	[ReversalReasonId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[EscrowGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NULL,
	[JobId] [bigint] NULL,
	[IsReceiptCreatedFromLockBox] [bit] NOT NULL,
	[ReversalAsOfDate] [datetimeoffset](7) NULL,
	[BranchId] [bigint] NULL,
	[OriginalReceiptId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[DealCountryId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_BankAccount]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_BillTo]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Branch]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_CashType] FOREIGN KEY([CashTypeId])
REFERENCES [dbo].[CashTypes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_CashType]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Contract]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_CostCenter]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Currency]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Customer]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_DealCountry] FOREIGN KEY([DealCountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_DealCountry]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Discounting]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_EscrowGLTemplate] FOREIGN KEY([EscrowGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_EscrowGLTemplate]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_InstrumentType]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_LegalEntity]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_LineofBusiness]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Location]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_OriginalReceipt] FOREIGN KEY([OriginalReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_OriginalReceipt]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_PayableCode]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_PayableRemitTo]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceiptBatch] FOREIGN KEY([ReceiptBatchId])
REFERENCES [dbo].[ReceiptBatches] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReceiptBatch]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceiptGLTemplate] FOREIGN KEY([ReceiptGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReceiptGLTemplate]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReceivableCode]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReceivableInvoice]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReversalReason] FOREIGN KEY([ReversalReasonId])
REFERENCES [dbo].[ReceiptReversalReasons] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_ReversalReason]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Sundry]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Type] FOREIGN KEY([TypeId])
REFERENCES [dbo].[ReceiptTypes] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Type]
GO
ALTER TABLE [dbo].[Receipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Receipts] CHECK CONSTRAINT [EReceipt_Vendor]
GO
