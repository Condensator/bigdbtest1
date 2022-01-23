SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayablePaymentVouchers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestedDate] [date] NOT NULL,
	[OverNightRequired] [bit] NOT NULL,
	[IsManual] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentVoucherId] [bigint] NOT NULL,
	[AccountsPayablePaymentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayablePaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_AccountsPayablePaymentVouchers] FOREIGN KEY([AccountsPayablePaymentId])
REFERENCES [dbo].[AccountsPayablePayments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AccountsPayablePaymentVouchers] CHECK CONSTRAINT [EAccountsPayablePayment_AccountsPayablePaymentVouchers]
GO
ALTER TABLE [dbo].[AccountsPayablePaymentVouchers]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePaymentVoucher_PaymentVoucher] FOREIGN KEY([PaymentVoucherId])
REFERENCES [dbo].[PaymentVouchers] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayablePaymentVouchers] CHECK CONSTRAINT [EAccountsPayablePaymentVoucher_PaymentVoucher]
GO
