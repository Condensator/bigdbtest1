SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetValueHistoryDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountPosted_Amount] [decimal](16, 2) NOT NULL,
	[AmountPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[AssetValueHistoryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetValueHistoryDetails]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistory_AssetValueHistoryDetails] FOREIGN KEY([AssetValueHistoryId])
REFERENCES [dbo].[AssetValueHistories] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetValueHistoryDetails] CHECK CONSTRAINT [EAssetValueHistory_AssetValueHistoryDetails]
GO
ALTER TABLE [dbo].[AssetValueHistoryDetails]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistoryDetail_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetValueHistoryDetails] CHECK CONSTRAINT [EAssetValueHistoryDetail_GLJournal]
GO
ALTER TABLE [dbo].[AssetValueHistoryDetails]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistoryDetail_ReceiptApplicationReceivableDetail] FOREIGN KEY([ReceiptApplicationReceivableDetailId])
REFERENCES [dbo].[ReceiptApplicationReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[AssetValueHistoryDetails] CHECK CONSTRAINT [EAssetValueHistoryDetail_ReceiptApplicationReceivableDetail]
GO
