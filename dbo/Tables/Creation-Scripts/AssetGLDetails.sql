SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetGLDetails](
	[Id] [bigint] NOT NULL,
	[HoldingStatus] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepreciationGLTemplateId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[OriginalInstrumentTypeId] [bigint] NULL,
	[OriginalLineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetGLDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAsset_AssetGLDetail]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_AssetBookValueAdjustmentGLTemplate] FOREIGN KEY([AssetBookValueAdjustmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_AssetBookValueAdjustmentGLTemplate]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_BookDepreciationGLTemplate] FOREIGN KEY([BookDepreciationGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_BookDepreciationGLTemplate]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_Branch]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_CostCenter]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_InstrumentType]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_OriginalInstrumentType] FOREIGN KEY([OriginalInstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_OriginalInstrumentType]
GO
ALTER TABLE [dbo].[AssetGLDetails]  WITH CHECK ADD  CONSTRAINT [EAssetGLDetail_OriginalLineofBusiness] FOREIGN KEY([OriginalLineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetGLDetails] CHECK CONSTRAINT [EAssetGLDetail_OriginalLineofBusiness]
GO
