SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSplits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SplitType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FeatureAssetId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSplits]  WITH CHECK ADD  CONSTRAINT [EAssetSplit_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AssetSplits] CHECK CONSTRAINT [EAssetSplit_BusinessUnit]
GO
ALTER TABLE [dbo].[AssetSplits]  WITH CHECK ADD  CONSTRAINT [EAssetSplit_FeatureAsset] FOREIGN KEY([FeatureAssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetSplits] CHECK CONSTRAINT [EAssetSplit_FeatureAsset]
GO
ALTER TABLE [dbo].[AssetSplits]  WITH CHECK ADD  CONSTRAINT [EAssetSplit_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[AssetSplits] CHECK CONSTRAINT [EAssetSplit_JobStepInstance]
GO
