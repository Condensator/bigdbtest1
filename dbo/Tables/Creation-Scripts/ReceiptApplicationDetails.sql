SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationDetails](
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationDetails]  WITH CHECK ADD  CONSTRAINT [EReceipt_ReceiptApplicationDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[Receipts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationDetails] CHECK CONSTRAINT [EReceipt_ReceiptApplicationDetail]
GO
ALTER TABLE [dbo].[ReceiptApplicationDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationDetail_ReceiptApplication] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationDetails] CHECK CONSTRAINT [EReceiptApplicationDetail_ReceiptApplication]
GO
