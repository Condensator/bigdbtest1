SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentVoucherInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RemittanceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RequestedDate] [date] NOT NULL,
	[PaymentVoucherStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Memo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PayeeName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[IsManual] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RemitToId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayFromAccountId] [bigint] NOT NULL,
	[AccountsPayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[BillToId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[ReceivableDueDate] [date] NULL,
	[ClearingOption] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[APGLTemplateId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EAccountsPayable_PaymentVoucherInfoes] FOREIGN KEY([AccountsPayableId])
REFERENCES [dbo].[AccountsPayables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EAccountsPayable_PaymentVoucherInfoes]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_APGLTemplate] FOREIGN KEY([APGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_APGLTemplate]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_BillTo]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_Branch]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_CostCenter]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_Currency]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_InstrumentType]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_LegalEntity]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_LineofBusiness] FOREIGN KEY([LineOfBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_LineofBusiness]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_Location]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_PayFromAccount] FOREIGN KEY([PayFromAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_PayFromAccount]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_ReceivableCode]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_RemitTo]
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_Sundry]
GO
