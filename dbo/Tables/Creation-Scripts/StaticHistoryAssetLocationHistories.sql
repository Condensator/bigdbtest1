SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StaticHistoryAssetLocationHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LocationEffectiveFromDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StaticHistoryLocationId] [bigint] NOT NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[StaticHistoryAssetLocationHistories]  WITH CHECK ADD  CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetLocationHistories] FOREIGN KEY([StaticHistoryAssetId])
REFERENCES [dbo].[StaticHistoryAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[StaticHistoryAssetLocationHistories] CHECK CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetLocationHistories]
GO
ALTER TABLE [dbo].[StaticHistoryAssetLocationHistories]  WITH CHECK ADD  CONSTRAINT [EStaticHistoryAssetLocationHistory_StaticHistoryLocation] FOREIGN KEY([StaticHistoryLocationId])
REFERENCES [dbo].[StaticHistoryLocations] ([Id])
GO
ALTER TABLE [dbo].[StaticHistoryAssetLocationHistories] CHECK CONSTRAINT [EStaticHistoryAssetLocationHistory_StaticHistoryLocation]
GO
