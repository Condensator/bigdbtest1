SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SKUValueProportions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value_Amount] [decimal](16, 2) NOT NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetValueHistoryId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SKUValueProportions]  WITH CHECK ADD  CONSTRAINT [ESKUValueProportion_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[SKUValueProportions] CHECK CONSTRAINT [ESKUValueProportion_AssetSKU]
GO
ALTER TABLE [dbo].[SKUValueProportions]  WITH CHECK ADD  CONSTRAINT [ESKUValueProportion_AssetValueHistory] FOREIGN KEY([AssetValueHistoryId])
REFERENCES [dbo].[AssetValueHistories] ([Id])
GO
ALTER TABLE [dbo].[SKUValueProportions] CHECK CONSTRAINT [ESKUValueProportion_AssetValueHistory]
GO
