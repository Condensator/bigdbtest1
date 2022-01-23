SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramAssetTypes](
	[IsUsageConditionRequired] [bit] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsModelYearRequired] [bit] NOT NULL,
	[ResidualMatrixAvailable] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MaximumAllowedAge] [int] NOT NULL,
	[ApprovedTerm] [int] NOT NULL,
	[FeeTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramAssetTypes]  WITH CHECK ADD  CONSTRAINT [EProgramAssetType_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[ProgramAssetTypes] CHECK CONSTRAINT [EProgramAssetType_AssetType]
GO
ALTER TABLE [dbo].[ProgramAssetTypes]  WITH CHECK ADD  CONSTRAINT [EProgramAssetType_FeeTemplate] FOREIGN KEY([FeeTemplateId])
REFERENCES [dbo].[FeeTemplates] ([Id])
GO
ALTER TABLE [dbo].[ProgramAssetTypes] CHECK CONSTRAINT [EProgramAssetType_FeeTemplate]
GO
ALTER TABLE [dbo].[ProgramAssetTypes]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_ProgramAssetTypes] FOREIGN KEY([ProgramDetailId])
REFERENCES [dbo].[ProgramDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramAssetTypes] CHECK CONSTRAINT [EProgramDetail_ProgramAssetTypes]
GO
