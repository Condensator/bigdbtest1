SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetFeatureSerialNumbers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[AssetFeatureId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetFeatureSerialNumbers]  WITH CHECK ADD  CONSTRAINT [EAssetFeature_AssetFeatureSerialNumbers] FOREIGN KEY([AssetFeatureId])
REFERENCES [dbo].[AssetFeatures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetFeatureSerialNumbers] CHECK CONSTRAINT [EAssetFeature_AssetFeatureSerialNumbers]
GO
