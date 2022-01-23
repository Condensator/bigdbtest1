SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationReceivableGroups](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[TaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookAmountApplied_Amount] [decimal](16, 2) NULL,
	[BookAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreviousAmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[PreviousAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousTaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[PreviousTaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousBookAmountApplied_Amount] [decimal](16, 2) NULL,
	[PreviousBookAmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsReApplication] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AdjustedWithHoldingTax_Amount] [decimal](16, 2) NOT NULL,
	[AdjustedWithHoldingTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivedAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreviousAdjustedWithHoldingTax_Amount] [decimal](16, 2) NOT NULL,
	[PreviousAdjustedWithHoldingTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableGroups]  WITH CHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableGroups] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableGroups] CHECK CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableGroups]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableGroups]  WITH CHECK ADD  CONSTRAINT [EReceiptApplicationReceivableGroup_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableGroups] CHECK CONSTRAINT [EReceiptApplicationReceivableGroup_Receivable]
GO
