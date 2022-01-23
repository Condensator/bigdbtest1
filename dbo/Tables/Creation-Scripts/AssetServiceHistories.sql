SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetServiceHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServiceDate] [date] NOT NULL,
	[AccountingDocumentNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ServiceAmountInclVAT_Amount] [decimal](16, 2) NOT NULL,
	[ServiceAmountInclVAT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ServiceConfigId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetServiceHistories]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetServiceHistories] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetServiceHistories] CHECK CONSTRAINT [EAsset_AssetServiceHistories]
GO
ALTER TABLE [dbo].[AssetServiceHistories]  WITH CHECK ADD  CONSTRAINT [EAssetServiceHistory_ServiceConfig] FOREIGN KEY([ServiceConfigId])
REFERENCES [dbo].[ServiceConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetServiceHistories] CHECK CONSTRAINT [EAssetServiceHistory_ServiceConfig]
GO
