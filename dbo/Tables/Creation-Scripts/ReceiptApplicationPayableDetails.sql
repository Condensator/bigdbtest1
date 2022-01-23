SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationPayableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TiedContractPaymentDetailId] [bigint] NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SundryId] [bigint] NOT NULL,
	[DiscountingContractId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationPayableDetail_DiscountingContract] FOREIGN KEY([DiscountingContractId])
REFERENCES [dbo].[DiscountingContracts] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails] CHECK CONSTRAINT [EReceiptApplicationPayableDetail_DiscountingContract]
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationPayableDetail_ReceiptApplicationReceivableDetail] FOREIGN KEY([ReceiptApplicationReceivableDetailId])
REFERENCES [dbo].[ReceiptApplicationReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails] CHECK CONSTRAINT [EReceiptApplicationPayableDetail_ReceiptApplicationReceivableDetail]
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationPayableDetail_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails] CHECK CONSTRAINT [EReceiptApplicationPayableDetail_Sundry]
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationPayableDetail_TiedContractPaymentDetail] FOREIGN KEY([TiedContractPaymentDetailId])
REFERENCES [dbo].[TiedContractPaymentDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationPayableDetails] CHECK CONSTRAINT [EReceiptApplicationPayableDetail_TiedContractPaymentDetail]
GO
