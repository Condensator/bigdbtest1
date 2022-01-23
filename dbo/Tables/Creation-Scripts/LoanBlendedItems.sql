SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Revise] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[PayableInvoiceOtherCostId] [bigint] NULL,
	[FundingSourceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[LoanBlendedItems] CHECK CONSTRAINT [ELoanBlendedItem_BlendedItem]
GO
ALTER TABLE [dbo].[LoanBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanBlendedItem_FundingSource] FOREIGN KEY([FundingSourceId])
REFERENCES [dbo].[LoanSyndicationFundingSources] ([Id])
GO
ALTER TABLE [dbo].[LoanBlendedItems] CHECK CONSTRAINT [ELoanBlendedItem_FundingSource]
GO
ALTER TABLE [dbo].[LoanBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanBlendedItem_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LoanBlendedItems] CHECK CONSTRAINT [ELoanBlendedItem_PayableInvoiceOtherCost]
GO
ALTER TABLE [dbo].[LoanBlendedItems]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanBlendedItems] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanBlendedItems] CHECK CONSTRAINT [ELoanFinance_LoanBlendedItems]
GO
