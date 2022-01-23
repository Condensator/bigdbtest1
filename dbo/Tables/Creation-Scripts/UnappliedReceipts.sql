SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnappliedReceipts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptAllocationId] [bigint] NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UnappliedReceipts]  WITH CHECK ADD  CONSTRAINT [EReceipt_UnappliedReceipts] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UnappliedReceipts] CHECK CONSTRAINT [EReceipt_UnappliedReceipts]
GO
ALTER TABLE [dbo].[UnappliedReceipts]  WITH CHECK ADD  CONSTRAINT [EUnappliedReceipt_ReceiptAllocation] FOREIGN KEY([ReceiptAllocationId])
REFERENCES [dbo].[ReceiptAllocations] ([Id])
GO
ALTER TABLE [dbo].[UnappliedReceipts] CHECK CONSTRAINT [EUnappliedReceipt_ReceiptAllocation]
GO
