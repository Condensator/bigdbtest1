SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetHoldingStatusChanges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[NewHoldingStatus] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GLTransferEffectiveDate] [date] NOT NULL,
	[BookDepreciationGLTemplateId] [bigint] NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChange_AssetBookValueAdjustmentGLTemplate] FOREIGN KEY([AssetBookValueAdjustmentGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges] CHECK CONSTRAINT [EAssetHoldingStatusChange_AssetBookValueAdjustmentGLTemplate]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChange_BookDepreciationGLTemplate] FOREIGN KEY([BookDepreciationGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges] CHECK CONSTRAINT [EAssetHoldingStatusChange_BookDepreciationGLTemplate]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChange_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges] CHECK CONSTRAINT [EAssetHoldingStatusChange_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetHoldingStatusChange_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AssetHoldingStatusChanges] CHECK CONSTRAINT [EAssetHoldingStatusChange_BusinessUnit]
GO
