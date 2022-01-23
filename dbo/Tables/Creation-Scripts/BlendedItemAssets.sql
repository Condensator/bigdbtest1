SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlendedItemAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxCredit_Amount] [decimal](16, 2) NOT NULL,
	[TaxCredit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxReduction_Amount] [decimal](16, 2) NOT NULL,
	[UpfrontTaxReduction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NewTaxBasis_Amount] [decimal](16, 2) NOT NULL,
	[NewTaxBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookBasis_Amount] [decimal](16, 2) NOT NULL,
	[BookBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxCreditTaxBasisPercentage] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlendedItemAssets]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_BlendedItemAssets] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BlendedItemAssets] CHECK CONSTRAINT [EBlendedItem_BlendedItemAssets]
GO
ALTER TABLE [dbo].[BlendedItemAssets]  WITH CHECK ADD  CONSTRAINT [EBlendedItemAsset_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemAssets] CHECK CONSTRAINT [EBlendedItemAsset_LeaseAsset]
GO
