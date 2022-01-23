SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrepaidReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PrePaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrePaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrePaidTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrePaidTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FinancingPrePaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[FinancingPrePaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PrepaidReceivables]  WITH CHECK ADD  CONSTRAINT [EPrepaidReceivable_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[PrepaidReceivables] CHECK CONSTRAINT [EPrepaidReceivable_Receipt]
GO
ALTER TABLE [dbo].[PrepaidReceivables]  WITH CHECK ADD  CONSTRAINT [EPrepaidReceivable_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[PrepaidReceivables] CHECK CONSTRAINT [EPrepaidReceivable_Receivable]
GO
