SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetSerialNumberHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OldSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetHistoryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetSerialNumberHistories]  WITH CHECK ADD  CONSTRAINT [EAssetHistory_AssetSerialNumberHistories] FOREIGN KEY([AssetHistoryId])
REFERENCES [dbo].[AssetHistories] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetSerialNumberHistories] CHECK CONSTRAINT [EAssetHistory_AssetSerialNumberHistories]
GO
