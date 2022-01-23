SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetTypeTaxDepreciations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CountryId] [bigint] NOT NULL,
	[DomesticTaxDepTemplateId] [bigint] NULL,
	[InternationalTaxDepTemplateId] [bigint] NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations]  WITH CHECK ADD  CONSTRAINT [EAssetType_AssetTypeTaxDepreciations] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations] CHECK CONSTRAINT [EAssetType_AssetTypeTaxDepreciations]
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations]  WITH CHECK ADD  CONSTRAINT [EAssetTypeTaxDepreciation_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations] CHECK CONSTRAINT [EAssetTypeTaxDepreciation_Country]
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations]  WITH CHECK ADD  CONSTRAINT [EAssetTypeTaxDepreciation_DomesticTaxDepTemplate] FOREIGN KEY([DomesticTaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations] CHECK CONSTRAINT [EAssetTypeTaxDepreciation_DomesticTaxDepTemplate]
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations]  WITH CHECK ADD  CONSTRAINT [EAssetTypeTaxDepreciation_InternationalTaxDepTemplate] FOREIGN KEY([InternationalTaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetTypeTaxDepreciations] CHECK CONSTRAINT [EAssetTypeTaxDepreciation_InternationalTaxDepTemplate]
GO
