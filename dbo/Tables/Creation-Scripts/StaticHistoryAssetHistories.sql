SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StaticHistoryAssetHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AsofDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ParentAssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionDate] [date] NULL,
	[Contract] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[StaticHistoryAssetHistories]  WITH CHECK ADD  CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetHistories] FOREIGN KEY([StaticHistoryAssetId])
REFERENCES [dbo].[StaticHistoryAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[StaticHistoryAssetHistories] CHECK CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetHistories]
GO
