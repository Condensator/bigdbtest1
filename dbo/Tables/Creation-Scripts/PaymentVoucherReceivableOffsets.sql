SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentVoucherReceivableOffsets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountToApply_Amount] [decimal](16, 2) NOT NULL,
	[AmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NOT NULL,
	[PaymentVoucherId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxToApply_Amount] [decimal](16, 2) NOT NULL,
	[TaxToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaymentVoucherReceivableOffsets]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_PaymentVoucherReceivableOffsets] FOREIGN KEY([PaymentVoucherId])
REFERENCES [dbo].[PaymentVouchers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaymentVoucherReceivableOffsets] CHECK CONSTRAINT [EPaymentVoucher_PaymentVoucherReceivableOffsets]
GO
ALTER TABLE [dbo].[PaymentVoucherReceivableOffsets]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherReceivableOffset_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[AccountsPayableReceivables] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherReceivableOffsets] CHECK CONSTRAINT [EPaymentVoucherReceivableOffset_Receivable]
GO
