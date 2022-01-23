SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSaleReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InstallmentNumber] [bigint] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tax_Amount] [decimal](16, 2) NOT NULL,
	[Tax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NULL,
	[SundryRecurringId] [bigint] NULL,
	[SundryReceivableId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleReceivables] FOREIGN KEY([AssetSaleId])
REFERENCES [dbo].[AssetSales] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSale_AssetSaleReceivables]
GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSaleReceivable_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSaleReceivable_Contract]
GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSaleReceivable_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSaleReceivable_LegalEntity]
GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSaleReceivable_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSaleReceivable_Receivable]
GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSaleReceivable_SundryReceivable] FOREIGN KEY([SundryReceivableId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSaleReceivable_SundryReceivable]
GO
ALTER TABLE [dbo].[AssetSaleReceivables]  WITH CHECK ADD  CONSTRAINT [EAssetSaleReceivable_SundryRecurring] FOREIGN KEY([SundryRecurringId])
REFERENCES [dbo].[SundryRecurrings] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleReceivables] CHECK CONSTRAINT [EAssetSaleReceivable_SundryRecurring]
GO
