SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetDetails](
	[Id] [bigint] NOT NULL,
	[DateofProduction] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AgeofAsset] [decimal](16, 2) NOT NULL,
	[KW] [decimal](16, 2) NULL,
	[EngineCapacity] [decimal](16, 2) NULL,
	[ValueExclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueExclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ValueInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ValueInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MakeId] [bigint] NOT NULL,
	[ModelId] [bigint] NOT NULL,
	[TaxCodeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsVAT] [bit] NOT NULL,
	[AssetClassConfigId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetDetail_AssetClassConfig] FOREIGN KEY([AssetClassConfigId])
REFERENCES [dbo].[AssetClassConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetDetails] CHECK CONSTRAINT [EAssetDetail_AssetClassConfig]
GO
ALTER TABLE [dbo].[AssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetDetail_Make] FOREIGN KEY([MakeId])
REFERENCES [dbo].[Makes] ([Id])
GO
ALTER TABLE [dbo].[AssetDetails] CHECK CONSTRAINT [EAssetDetail_Make]
GO
ALTER TABLE [dbo].[AssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetDetail_Model] FOREIGN KEY([ModelId])
REFERENCES [dbo].[Models] ([Id])
GO
ALTER TABLE [dbo].[AssetDetails] CHECK CONSTRAINT [EAssetDetail_Model]
GO
ALTER TABLE [dbo].[AssetDetails]  WITH CHECK ADD  CONSTRAINT [EAssetDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[AssetDetails] CHECK CONSTRAINT [EAssetDetail_TaxCode]
GO
ALTER TABLE [dbo].[AssetDetails]  WITH CHECK ADD  CONSTRAINT [EQuote_AssetDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[Quotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetDetails] CHECK CONSTRAINT [EQuote_AssetDetail]
GO
