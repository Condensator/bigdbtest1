SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSplitDetailInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NewAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[NewAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Weightage] [decimal](28, 18) NULL,
	[NewQuantity] [int] NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetSplitDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSplitDetailInfoes]  WITH CHECK ADD  CONSTRAINT [EAssetSplitDetail_AssetSplitDetailInfoes] FOREIGN KEY([AssetSplitDetailId])
REFERENCES [dbo].[AssetSplitDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSplitDetailInfoes] CHECK CONSTRAINT [EAssetSplitDetail_AssetSplitDetailInfoes]
GO
