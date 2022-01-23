SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[TaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookAmountApplied_Amount] [decimal](16, 2) NULL,
	[BookAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreviousAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[PreviousAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousBookAmountApplied_Amount] [decimal](16, 2) NULL,
	[PreviousBookAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreviousTaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[PreviousTaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsTaxGLPosted] [bit] NOT NULL,
	[RecoveryAmount_Amount] [decimal](16, 2) NOT NULL,
	[RecoveryAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GainAmount_Amount] [decimal](16, 2) NOT NULL,
	[GainAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsReApplication] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[ReceiptApplicationInvoiceId] [bigint] NULL,
	[ReceiptApplicationReceivableGroupId] [bigint] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[PayableId] [bigint] NULL,
	[SundryPayableId] [bigint] NULL,
	[SundryReceivableId] [bigint] NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpfrontTaxSundryId] [bigint] NULL,
	[PrepaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrepaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrepaidTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrepaidTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdjustedWithholdingTax_Amount] [decimal](16, 2) NOT NULL,
	[AdjustedWithholdingTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivedAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousAdjustedWithHoldingTax_Amount] [decimal](16, 2) NOT NULL,
	[PreviousAdjustedWithHoldingTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrevLeaseComponentAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[PrevLeaseComponentAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrevNonLeaseComponentAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[PrevNonLeaseComponentAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithHoldingTaxBookAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithHoldingTaxBookAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[ReceivedTowardsInterest_Amount] [decimal](16, 2) NOT NULL,
	[ReceivedTowardsInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentPrepaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentPrepaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentPrepaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentPrepaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableDetails] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableDetails]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_Payable]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_ReceiptApplicationInvoice] FOREIGN KEY([ReceiptApplicationInvoiceId])
REFERENCES [dbo].[ReceiptApplicationInvoices] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_ReceiptApplicationInvoice]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_ReceiptApplicationReceivableGroup] FOREIGN KEY([ReceiptApplicationReceivableGroupId])
REFERENCES [dbo].[ReceiptApplicationReceivableGroups] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_ReceiptApplicationReceivableGroup]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_ReceivableInvoice]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_SundryPayable] FOREIGN KEY([SundryPayableId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_SundryPayable]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_SundryReceivable] FOREIGN KEY([SundryReceivableId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_SundryReceivable]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableDetail_UpfrontTaxSundry] FOREIGN KEY([UpfrontTaxSundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableDetails] CHECK CONSTRAINT [EReceiptApplicationReceivableDetail_UpfrontTaxSundry]
GO
