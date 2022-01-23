SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetTypeForFMVs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[AssetFMVMatrixId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetTypeForFMVs]  WITH CHECK ADD  CONSTRAINT [EAssetFMVMatrix_AssetTypeForFMVs] FOREIGN KEY([AssetFMVMatrixId])
REFERENCES [dbo].[AssetFMVMatrices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetTypeForFMVs] CHECK CONSTRAINT [EAssetFMVMatrix_AssetTypeForFMVs]
GO
ALTER TABLE [dbo].[AssetTypeForFMVs]  WITH CHECK ADD  CONSTRAINT [EAssetTypeForFMV_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetTypeForFMVs] CHECK CONSTRAINT [EAssetTypeForFMV_AssetType]
GO
