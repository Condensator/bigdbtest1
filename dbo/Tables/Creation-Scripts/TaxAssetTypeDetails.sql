SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxAssetTypeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[TaxAssetTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxAssetTypeDetails]  WITH CHECK ADD  CONSTRAINT [ETaxAssetType_TaxAssetTypeDetails] FOREIGN KEY([TaxAssetTypeId])
REFERENCES [dbo].[TaxAssetTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxAssetTypeDetails] CHECK CONSTRAINT [ETaxAssetType_TaxAssetTypeDetails]
GO
ALTER TABLE [dbo].[TaxAssetTypeDetails]  WITH CHECK ADD  CONSTRAINT [ETaxAssetTypeDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxAssetTypeDetails] CHECK CONSTRAINT [ETaxAssetTypeDetail_AssetType]
GO
