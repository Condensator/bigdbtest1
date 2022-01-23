SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionReceipts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceiptBalance_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreditApplied_Amount] [decimal](16, 2) NOT NULL,
	[CreditApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToNewCustomer_Amount] [decimal](16, 2) NOT NULL,
	[TransferToNewCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BalanceWithOldCustomer_Amount] [decimal](16, 2) NOT NULL,
	[BalanceWithOldCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionReceipts]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionReceipts] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionReceipts] CHECK CONSTRAINT [EAssumption_AssumptionReceipts]
GO
ALTER TABLE [dbo].[AssumptionReceipts]  WITH CHECK ADD  CONSTRAINT [EAssumptionReceipt_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[AssumptionReceipts] CHECK CONSTRAINT [EAssumptionReceipt_Receipt]
GO
