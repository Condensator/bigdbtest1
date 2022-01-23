SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableSKUs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PreCapitalizationRent_Amount] [decimal](16, 2) NOT NULL,
	[PreCapitalizationRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableSKUs]  WITH NOCHECK ADD  CONSTRAINT [EReceivableDetail_ReceivableSKUs] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableSKUs] NOCHECK CONSTRAINT [EReceivableDetail_ReceivableSKUs]
GO
ALTER TABLE [dbo].[ReceivableSKUs]  WITH NOCHECK ADD  CONSTRAINT [EReceivableSKU_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableSKUs] NOCHECK CONSTRAINT [EReceivableSKU_AssetSKU]
GO
