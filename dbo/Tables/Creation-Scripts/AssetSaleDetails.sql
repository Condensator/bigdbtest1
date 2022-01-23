SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSaleDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FairMarketValue_Amount] [decimal](16, 2) NOT NULL,
	[FairMarketValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveToDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TerminationReasonConfigId] [bigint] NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[ProjectedVATAmount_Amount] [decimal](16, 2) NULL,
	[ProjectedVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSaleDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSale_AssetSaleDetails] FOREIGN KEY([AssetSaleId])
REFERENCES [dbo].[AssetSales] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSaleDetails] CHECK CONSTRAINT [EAssetSale_AssetSaleDetails]
GO
ALTER TABLE [dbo].[AssetSaleDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSaleDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleDetails] CHECK CONSTRAINT [EAssetSaleDetail_Asset]
GO
ALTER TABLE [dbo].[AssetSaleDetails]  WITH CHECK ADD  CONSTRAINT [EAssetSaleDetail_TerminationReasonConfig] FOREIGN KEY([TerminationReasonConfigId])
REFERENCES [dbo].[TerminationReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetSaleDetails] CHECK CONSTRAINT [EAssetSaleDetail_TerminationReasonConfig]
GO
