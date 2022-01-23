SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileShellAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ModalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NOT NULL,
	[ManufacturerName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentLocation] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentDescription] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[UsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[InServiceDate] [date] NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogId] [bigint] NULL,
	[IsRealAsset] [bit] NOT NULL,
	[AssetId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[Model] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SellingPrice_Amount] [decimal](16, 2) NULL,
	[SellingPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ProposalShellAssetId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileShellAssets] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfile_CreditProfileShellAssets]
GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfileShellAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfileShellAsset_Asset]
GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfileShellAsset_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfileShellAsset_AssetCatalog]
GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfileShellAsset_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfileShellAsset_AssetType]
GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfileShellAsset_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfileShellAsset_Location]
GO
ALTER TABLE [dbo].[CreditProfileShellAssets]  WITH CHECK ADD  CONSTRAINT [ECreditProfileShellAsset_ProposalShellAsset] FOREIGN KEY([ProposalShellAssetId])
REFERENCES [dbo].[ProposalShellAssets] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileShellAssets] CHECK CONSTRAINT [ECreditProfileShellAsset_ProposalShellAsset]
GO
