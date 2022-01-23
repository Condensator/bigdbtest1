SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RACAssetTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetTypeId] [bigint] NULL,
	[RACId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RACAssetTypes]  WITH CHECK ADD  CONSTRAINT [ERAC_RACAssetTypes] FOREIGN KEY([RACId])
REFERENCES [dbo].[RACs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RACAssetTypes] CHECK CONSTRAINT [ERAC_RACAssetTypes]
GO
ALTER TABLE [dbo].[RACAssetTypes]  WITH CHECK ADD  CONSTRAINT [ERACAssetType_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[RACAssetTypes] CHECK CONSTRAINT [ERACAssetType_AssetType]
GO
