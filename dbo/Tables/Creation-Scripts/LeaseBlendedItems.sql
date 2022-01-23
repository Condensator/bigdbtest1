SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Revise] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NULL,
	[FundingSourceId] [bigint] NULL,
	[FundingId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FeeDetailId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseBlendedItem_BlendedItem]
GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_FeeDetail] FOREIGN KEY([FeeDetailId])
REFERENCES [dbo].[FeeDetails] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseBlendedItem_FeeDetail]
GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_Funding] FOREIGN KEY([FundingId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseBlendedItem_Funding]
GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_FundingSource] FOREIGN KEY([FundingSourceId])
REFERENCES [dbo].[LeaseSyndicationFundingSources] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseBlendedItem_FundingSource]
GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseBlendedItem_PayableInvoiceOtherCost]
GO
ALTER TABLE [dbo].[LeaseBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseBlendedItems] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseBlendedItems] CHECK CONSTRAINT [ELeaseFinance_LeaseBlendedItems]
GO
