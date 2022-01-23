SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentVoucherDetailInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableOffsetAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableOffsetAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccountsPayableDetailId] [bigint] NOT NULL,
	[PaymentVoucherInfoId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaymentVoucherDetailInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherDetailInfo_AccountsPayableDetail] FOREIGN KEY([AccountsPayableDetailId])
REFERENCES [dbo].[AccountsPayableDetails] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherDetailInfoes] CHECK CONSTRAINT [EPaymentVoucherDetailInfo_AccountsPayableDetail]
GO
ALTER TABLE [dbo].[PaymentVoucherDetailInfoes]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherInfo_PaymentVoucherDetailInfoes] FOREIGN KEY([PaymentVoucherInfoId])
REFERENCES [dbo].[PaymentVoucherInfoes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaymentVoucherDetailInfoes] CHECK CONSTRAINT [EPaymentVoucherInfo_PaymentVoucherDetailInfoes]
GO
