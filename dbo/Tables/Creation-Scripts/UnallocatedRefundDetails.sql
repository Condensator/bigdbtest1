SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnallocatedRefundDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountToBeCleared_Amount] [decimal](16, 2) NOT NULL,
	[AmountToBeCleared_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptAllocationId] [bigint] NOT NULL,
	[UnallocatedRefundId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UnallocatedRefundDetails]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefund_UnallocatedRefundDetails] FOREIGN KEY([UnallocatedRefundId])
REFERENCES [dbo].[UnallocatedRefunds] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UnallocatedRefundDetails] CHECK CONSTRAINT [EUnallocatedRefund_UnallocatedRefundDetails]
GO
ALTER TABLE [dbo].[UnallocatedRefundDetails]  WITH CHECK ADD  CONSTRAINT [EUnallocatedRefundDetail_ReceiptAllocation] FOREIGN KEY([ReceiptAllocationId])
REFERENCES [dbo].[ReceiptAllocations] ([Id])
GO
ALTER TABLE [dbo].[UnallocatedRefundDetails] CHECK CONSTRAINT [EUnallocatedRefundDetail_ReceiptAllocation]
GO
