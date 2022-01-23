SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlueBooks](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Model] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ManufacturerId] [bigint] NOT NULL,
	[AssetCategoryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlueBooks]  WITH CHECK ADD  CONSTRAINT [EBlueBook_AssetCategory] FOREIGN KEY([AssetCategoryId])
REFERENCES [dbo].[AssetCategories] ([Id])
GO
ALTER TABLE [dbo].[BlueBooks] CHECK CONSTRAINT [EBlueBook_AssetCategory]
GO
ALTER TABLE [dbo].[BlueBooks]  WITH CHECK ADD  CONSTRAINT [EBlueBook_Manufacturer] FOREIGN KEY([ManufacturerId])
REFERENCES [dbo].[Manufacturers] ([Id])
GO
ALTER TABLE [dbo].[BlueBooks] CHECK CONSTRAINT [EBlueBook_Manufacturer]
GO
