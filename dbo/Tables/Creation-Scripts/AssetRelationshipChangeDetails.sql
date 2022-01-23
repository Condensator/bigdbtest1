SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetRelationshipChangeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsChild] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetRelationshipChangeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetRelationshipChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetRelationshipChange_AssetRelationshipChangeDetails] FOREIGN KEY([AssetRelationshipChangeId])
REFERENCES [dbo].[AssetRelationshipChanges] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetRelationshipChangeDetails] CHECK CONSTRAINT [EAssetRelationshipChange_AssetRelationshipChangeDetails]
GO
ALTER TABLE [dbo].[AssetRelationshipChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetRelationshipChangeDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetRelationshipChangeDetails] CHECK CONSTRAINT [EAssetRelationshipChangeDetail_Asset]
GO
