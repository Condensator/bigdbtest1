SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StaticHistoryAssetValueHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AsOfDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Transaction] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalCost_Amount] [decimal](16, 2) NOT NULL,
	[OriginalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ChangeInAmount_Amount] [decimal](16, 2) NOT NULL,
	[ChangeInAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[StaticHistoryAssetValueHistories]  WITH CHECK ADD  CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetValueHistories] FOREIGN KEY([StaticHistoryAssetId])
REFERENCES [dbo].[StaticHistoryAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[StaticHistoryAssetValueHistories] CHECK CONSTRAINT [EStaticHistoryAsset_StaticHistoryAssetValueHistories]
GO
