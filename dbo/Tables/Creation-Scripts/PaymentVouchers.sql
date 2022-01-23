SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentVouchers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VoucherNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentDate] [date] NOT NULL,
	[PostDate] [date] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountInContractCurrency_Amount] [decimal](16, 2) NOT NULL,
	[AmountInContractCurrency_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CheckNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CheckDate] [date] NULL,
	[FederalReferenceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[WireDate] [date] NULL,
	[Memo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[OverNightRequired] [bit] NOT NULL,
	[OFACReviewRequired] [bit] NOT NULL,
	[IsManual] [bit] NOT NULL,
	[OriginalVoucherId] [bigint] NULL,
	[BatchId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[PayFromAccountId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsIntercompany] [bit] NOT NULL,
	[PaymentVoucherInfoId] [bigint] NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[AssessmentDate] [date] NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PaymentVouchers] CHECK CONSTRAINT [EPaymentVoucher_LegalEntity]
GO
ALTER TABLE [dbo].[PaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_PayFromAccount] FOREIGN KEY([PayFromAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[PaymentVouchers] CHECK CONSTRAINT [EPaymentVoucher_PayFromAccount]
GO
ALTER TABLE [dbo].[PaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_PaymentVoucherInfo] FOREIGN KEY([PaymentVoucherInfoId])
REFERENCES [dbo].[PaymentVoucherInfoes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVouchers] CHECK CONSTRAINT [EPaymentVoucher_PaymentVoucherInfo]
GO
ALTER TABLE [dbo].[PaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[PaymentVouchers] CHECK CONSTRAINT [EPaymentVoucher_Receipt]
GO
ALTER TABLE [dbo].[PaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PaymentVouchers] CHECK CONSTRAINT [EPaymentVoucher_RemitTo]
GO
