SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptBatchDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceiptBatchId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptBatchDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptBatch_ReceiptBatchDetails] FOREIGN KEY([ReceiptBatchId])
REFERENCES [dbo].[ReceiptBatches] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptBatchDetails] CHECK CONSTRAINT [EReceiptBatch_ReceiptBatchDetails]
GO
ALTER TABLE [dbo].[ReceiptBatchDetails]  WITH CHECK ADD  CONSTRAINT [EReceiptBatchDetail_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[ReceiptBatchDetails] CHECK CONSTRAINT [EReceiptBatchDetail_Receipt]
GO
